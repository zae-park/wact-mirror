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
  target_table: 'posts' | 'reviews'
  target_id: number
  author_id: string
  content: string
}

// WebhookPayload 인터페이스 정의
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

  let notificationTitle = ''
  let notificationBody = ''

  if (payload.table === 'posts') {
    // 새 글 알림 로직
    const record = payload.record as Post

    notificationTitle = '새 글!'
    notificationBody = `[${record.title}]`

    // 작성자 제외 모든 사용자 가져오기
    const { data: users, error } = await supabase
      .from('profiles')
      .select('id, fcm_token')
      .not('id', 'eq', record.author_id) // 작성자 제외

    if (error || !users) {
      return new Response('사용자 목록을 가져올 수 없습니다.', { status: 400 })
    }

    // 각 사용자에게 푸시 알림 전송
    for (const user of users) {
      if (!user.fcm_token) continue
      await sendPushNotification(user.fcm_token, notificationTitle, notificationBody)
    }

    return new Response('새 글 알림 전송 완료', { status: 200 })

  } else if (payload.table === 'reviews') {
    // 새 글 알림 로직
    const record = payload.record as Review
    const branches = ['강남', '시내', '신촌', '인천', '태릉']

    if (branches.includes(record.team)) {
      notificationTitle = `[${record.team}지부] 후기`
    } else {
      notificationTitle = `[${record.team}] 후기`
    }
    notificationBody = `${record.title}`

    // 작성자 제외 모든 사용자 가져오기
    const { data: users, error } = await supabase
      .from('profiles')
      .select('id, fcm_token')
      .not('id', 'eq', record.author_id) // 작성자 제외

    if (error || !users) {
      return new Response('사용자 목록을 가져올 수 없습니다.', { status: 400 })
    }

    // 각 사용자에게 푸시 알림 전송
    for (const user of users) {
      if (!user.fcm_token) continue
      await sendPushNotification(user.fcm_token, notificationTitle, notificationBody)
    }

    return new Response('새 글 알림 전송 완료', { status: 200 })
  } else if (payload.table === 'comments') {
    // 댓글 알림 로직
    const commentRecord = payload.record as Comment

    // 댓글 대상 게시글 또는 후기의 작성자 가져오기
    const { data: target, error } = await supabase
      .from(commentRecord.target_table)
      .select('author_id, title, author')
      .eq('id', commentRecord.target_id)
      .single()

    if (error || !target) {
      return new Response('댓글 대상 정보를 가져오지 못했습니다.', { status: 400 })
    }

    // 댓글 작성자가 대상 작성자인 경우 알림 생략
    if (target.author_id === commentRecord.author_id) {
      return new Response('댓글 작성자가 대상 작성자이므로 알림 생략', { status: 200 })
    }

    notificationTitle = `'${target.author}'님의 댓글!`
    notificationBody = `[${target.title}]에 새로운 댓글이 있습니다.`

    // 대상 작성자의 FCM 토큰 가져오기
    const { data: profile, error: profileError } = await supabase
      .from('profiles')
      .select('fcm_token')
      .eq('id', target.author_id)
      .single()

    if (profileError || !profile || !profile.fcm_token) {
      return new Response('FCM 토큰을 찾을 수 없습니다.', { status: 404 })
    }

    // 댓글 알림 전송
    await sendPushNotification(profile.fcm_token, notificationTitle, notificationBody)

    return new Response('댓글 알림 전송 완료', { status: 200 })
  } else {
    return new Response('알 수 없는 테이블', { status: 400 })
  }
})

// 공통 푸시 알림 함수
async function sendPushNotification(
  fcmToken: string,
  title: string,
  body: string
) {
  const { default: serviceAccount } = await import('../service-account.json', {
    with: { type: 'json' },
  })

  const accessToken = await getAccessToken({
    clientEmail: serviceAccount.client_email,
    privateKey: serviceAccount.private_key,
  })

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
            title,
            body,
          },
        },
      }),
    }
  )

  const resData = await res.json()
  if (res.status < 200 || res.status > 299) {
    console.error('푸시 알림 전송 실패:', resData)
  }
}

// Firebase Access Token 함수
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
