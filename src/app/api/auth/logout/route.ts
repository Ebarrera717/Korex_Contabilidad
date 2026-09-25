import { NextResponse } from 'next/server';

export async function POST() {
  const response = NextResponse.json({ success: true, message: 'Sesión cerrada correctamente' });

  response.cookies.set({
    name: 'auth_token',
    value: '',
    path: '/',
    expires: new Date(0)
  });

  response.cookies.set({
    name: 'user_name',
    value: '',
    path: '/',
    expires: new Date(0)
  });

  response.cookies.set({
    name: 'user_email',
    value: '',
    path: '/',
    expires: new Date(0)
  });

  return response;
}
