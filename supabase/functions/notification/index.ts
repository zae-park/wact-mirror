import { createClient } from 'npm:@supabase/supabase-js@2'
import { JWT } from 'npm:google-auth-library@9'

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

interface WebhookNewpost {
  type: 'INSERT'
  table: string
  record: Post
  schema: 'public'
  old_record: null | Post
}
                 
// Supabase 클라이언트 생성
const supabase = createClient(
  Deno.env.get('SUPABASE_URL')!,
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
)

Deno.serve(async (req) => {
  const payload: WebhookNewpost = await req.json()

  // 테이블에 따라 처리 분기
  let notificationTitle = '';
  let notificationBody = '';

  if (payload.table === 'posts') {
    // 일반 게시글
    notificationTitle = '새 글!';
    notificationBody = `[${payload.record.title}]`;
  } else if (payload.table === 'reviews') {
    // 후기 게시글
    const reviewRecord = payload.record as Review;
    const branches = ['강남', '시내', '신촌', '인천', '태릉'];
    
    // 팀이 특정 지부일 경우와 그렇지 않을 경우 구분
    if (branches.includes(reviewRecord.team)) {
      notificationTitle = `[${reviewRecord.team}지부] 후기`;
    } else {
      notificationTitle = `[${reviewRecord.team}] 후기`;
    }
    notificationBody = `${reviewRecord.title}`;
  } else {
    return new Response('알 수 없는 테이블', { status: 400 });
  }

  // 프로필 데이터에서 작성자(author)를 제외하고, fcm_token이 존재하는 사용자들의 토큰만 필터링
  const { data: profiles, error } = await supabase
    .from('profiles')
    .select('id, fcm_token')

  if (error || !profiles) {
    return new Response('로그_FCM Tokens not found', { status: 404 })
  }

  // 작성자를 제외하고, fcm_token이 있는 사용자만 필터링
  const filteredTokens = profiles
    .filter((profile) => profile.id !== payload.record.author_id && profile.fcm_token !== null)
    .map((profile) => profile.fcm_token)

  if (filteredTokens.length === 0) {
    return new Response('로그_No valid FCM tokens for push notification', { status: 200 })
  }

  const { default: serviceAccount } = await import('../service-account.json', {
    with: { type: 'json' },
  })

  const accessToken = await getAccessToken({
    clientEmail: serviceAccount.client_email,
    privateKey: serviceAccount.private_key,
  })

  // 각 fcm_token에 대해 푸시 알림 전송
  for (const fcmToken of filteredTokens) {
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
              title: notificationTitle,    // 분기된 제목 사용
              body: notificationBody,       // 분기된 본문 사용
            },
          },
        }),
      }
    )

    const resData = await res.json()
    if (res.status < 200 || 299 < res.status) {
      console.error('푸시 알림 전송 실패:', resData)
    }
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
