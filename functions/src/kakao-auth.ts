/**
 * Kakao Authentication Cloud Function
 *
 * Verifies Kakao access token and creates Firebase custom token.
 */

import * as admin from 'firebase-admin';
import { onCall, HttpsError } from 'firebase-functions/v2/https';
import fetch from 'node-fetch';

// Initialize Firebase Admin if not already initialized
if (admin.apps.length === 0) {
  admin.initializeApp();
}

interface KakaoUserInfo {
  id: number;
  kakao_account?: {
    email?: string;
    profile?: {
      nickname?: string;
      profile_image_url?: string;
    };
  };
}

/**
 * Verifies Kakao access token with Kakao API
 */
async function getKakaoUserInfo(accessToken: string): Promise<KakaoUserInfo> {
  const response = await fetch('https://kapi.kakao.com/v2/user/me', {
    headers: {
      Authorization: `Bearer ${accessToken}`,
      'Content-Type': 'application/x-www-form-urlencoded;charset=utf-8',
    },
  });

  if (!response.ok) {
    throw new HttpsError('unauthenticated', 'Invalid Kakao access token');
  }

  return response.json() as Promise<KakaoUserInfo>;
}

/**
 * Cloud Function: verifyKakaoToken
 *
 * Receives Kakao access token from client, verifies it,
 * and returns a Firebase custom token for authentication.
 */
export const verifyKakaoToken = onCall(async (request) => {
  const { accessToken } = request.data;

  // Validate input
  if (!accessToken || typeof accessToken !== 'string') {
    throw new HttpsError('invalid-argument', 'Access token is required');
  }

  try {
    // Verify token with Kakao API and get user info
    const kakaoUser = await getKakaoUserInfo(accessToken);

    if (!kakaoUser.id) {
      throw new HttpsError('unauthenticated', 'Failed to get Kakao user ID');
    }

    // Create unique Firebase UID for Kakao user
    const uid = `kakao:${kakaoUser.id}`;

    // Prepare user data for Firebase Auth
    const email = kakaoUser.kakao_account?.email;
    const displayName = kakaoUser.kakao_account?.profile?.nickname;
    const photoURL = kakaoUser.kakao_account?.profile?.profile_image_url;

    // Create or update Firebase Auth user
    try {
      await admin.auth().updateUser(uid, {
        ...(email && { email }),
        ...(displayName && { displayName }),
        ...(photoURL && { photoURL }),
      });
    } catch (error: unknown) {
      // User doesn't exist, create new user
      if ((error as { code?: string }).code === 'auth/user-not-found') {
        await admin.auth().createUser({
          uid,
          ...(email && { email }),
          ...(displayName && { displayName }),
          ...(photoURL && { photoURL }),
        });
      } else {
        throw error;
      }
    }

    // Create custom token for Firebase Auth
    const customToken = await admin.auth().createCustomToken(uid, {
      provider: 'kakao',
      kakaoId: kakaoUser.id,
    });

    return { customToken };
  } catch (error) {
    console.error('Kakao authentication error:', error);

    if (error instanceof HttpsError) {
      throw error;
    }

    throw new HttpsError('internal', 'Authentication failed');
  }
});
