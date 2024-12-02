import { createClient } from 'npm:@supabase/supabase-js@2'
import { JWT } from 'npm:google-auth-library@9'

// Post와 Review 인터페이스 정의
interface Post {
  id: number
  author_id: string
  author: string
  title: string
}

interface Review {
  id: number
  author_id: string
  author: string
  title: string
  team: string
}

interface Comment {
  id: string
  post_id: number
  author_id: string
  content: string
}

// WebhookNewpost 인터페이스 정의
interface WebhookPayload {
  type: 'INSERT'
  table: string
  record: Post | Review | Comment
  schema: 'public'
  old_record: null | Post | Review | Comment
}

// Supabase 클라이언트 생성
const supabase = createClient(
  Deno.env.get('SUPABASE_URL')!,
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
)

Deno.serve(async (req) => {
  const payload: WebhookPayload = await req.json()

  // 알림 제목과 본문 초기화
  let notificationTitle = ''
  let notificationBody = ''
  let notificationTargetAuthorId: string | null = null

  if (payload.table === 'posts') {
    // 일반 게시글
    const postRecord = payload.record as Post
    notificationTitle = '새 글!'
    notificationBody = `[${postRecord.title}]`
    notificationTargetAuthorId = postRecord.author_id
  } else if (payload.table === 'reviews') {
    // 후기 게시글
    const reviewRecord = payload.record as Review
    const branches = ['강남', '시내', '신촌', '인천', '태릉']
    if (branches.includes(reviewRecord.team)) {
      notificationTitle = `[${reviewRecord.team}지부] 후기`
    } else {
      notificationTitle = `[${reviewRecord.team}] 후기`
    }
    notificationBody = `${reviewRecord.title}`
    notificationTargetAuthorId = reviewRecord.author_id
  } else if (payload.table === 'comments') {
    // 댓글
    const commentRecord = payload.record as Comment
    // 댓글 대상 게시글의 작성자 가져오기
    const { data: post, error } = await supabase
      .from('posts')
      .select('author_id, title')
      .eq('id', commentRecord.post_id)
      .single()

    if (error || !post) {
      return new Response('댓글 대상 게시글 정보를 가져오지 못했습니다.', { status: 400 })
    }

    // 댓글 작성자가 글 작성자인 경우 알림 생략
    if (post.author_id === commentRecord.author_id) {
      return new Response('댓글 작성자가 글 작성자이므로 알림 생략', { status: 200 })
    }

    notificationTitle = '새 댓글!'
    notificationBody = `게시글 [${post.title}]에 새로운 댓글이 있습니다.`
    notificationTargetAuthorId = post.author_id
  } else {
    return new Response('알 수 없는 테이블', { status: 400 })
  }

  // 푸시 알림 대상 유저의 FCM 토큰 가져오기
  const { data: profile, error: profileError } = await supabase
    .from('profiles')
    .select('fcm_token')
    .eq('id', notificationTargetAuthorId)
    .single()

  if (profileError || !profile || !profile.fcm_token) {
    return new Response('FCM 토큰을 찾을 수 없습니다.', { status: 404 })
  }

  const fcmToken = profile.fcm_token

  // Firebase Service Account 로드
  const { default: serviceAccount } = await import('../service-account.json', {
    with: { type: 'json' },
  })

  const accessToken = await getAccessToken({
    clientEmail: serviceAccount.client_email,
    privateKey: serviceAccount.private_key,
  })

  // 푸시 알림 전송
  const res = await fetch(
    `https://fcm.googleapis.com/v1/projects/${serviceAccount.project_id}/messages:send`,
    {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${accessToken}`,
      },
      body: JSON.stringify({
        message: {
          token: fcmToken,
          notification: {
            title: notificationTitle,
            body: notificationBody,
          },
          data: {
            click_action: payload.table === 'posts'
              ? `post_detail?id=${(payload.record as Post).id}`
              : payload.table === 'reviews'
              ? `review_detail?id=${(payload.record as Review).id}`
              : `post_detail?id=${(payload.record as Comment).post_id}`,
          },
        },
      }),
    }
  )

  const resData = await res.json()
  if (res.status < 200 || res.status > 299) {
    console.error('푸시 알림 전송 실패:', resData)
  }

  return new Response('푸시 알림 전송 완료', {
    headers: { 'Content-Type': 'application/json' },
  })
})

const getAccessToken = ({
  clientEmail,
  privateKey,
}: {
  clientEmail: string
  privateKey: string
}): Promise<string> => {
  return new Promise((resolve, reject) => {
    const jwtClient = new JWT({
      email: clientEmail,
      key: privateKey,
      scopes: ['https://www.googleapis.com/auth/firebase.messaging'],
    })
    jwtClient.authorize((err, tokens) => {
      if (err) {
        reject(err)
        return
      }
      resolve(tokens!.access_token!)
    })
  })
}
