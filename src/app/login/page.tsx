'use client';

import React, { useState } from 'react';
import { useRouter, useSearchParams } from 'next/navigation';
import {
  ShieldCheck,
  Lock,
  Mail,
  ArrowRight,
  Building2,
  AlertTriangle,
  HelpCircle,
  ChevronDown,
  ChevronUp,
  RefreshCw
} from 'lucide-react';

interface ErrorDetails {
  message: string;
  detail?: string;
  suggestion?: string;
  category?: 'DATABASE' | 'CREDENTIALS' | 'SERVER';
  errorCode?: string;
}

export default function LoginPage() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const redirectUrl = searchParams.get('redirect') || '/dashboard';

  const [email, setEmail] = useState('admin@korex.com.co');
  const [password, setPassword] = useState('Admin123*');
  const [loading, setLoading] = useState(false);
  const [errorDetails, setErrorDetails] = useState<ErrorDetails | null>(null);
  const [showTechnicalDetails, setShowTechnicalDetails] = useState(true);

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setErrorDetails(null);

    try {
      const res = await fetch('/api/auth/login', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email, password })
      });

      let data: any = {};
      const rawText = await res.text();

      try {
        data = JSON.parse(rawText);
      } catch {
        data = {
          message: `Error en respuesta del servidor (HTTP ${res.status})`,
          detail: rawText || 'El servidor devolvió una respuesta no válida (HTML o formato inesperado).',
          category: 'SERVER',
          suggestion: '1. Verifique que el servicio backend de Korex_Contabilidad esté activo.\n2. Revise las credenciales y el estado de la base de datos en .env'
        };
      }

      if (!res.ok || !data.success) {
        const details: ErrorDetails = {
          message: data.message || data.error || 'Error en el inicio de sesión',
          detail: data.detail || (typeof data.error === 'string' && data.error !== data.message ? data.error : undefined),
          suggestion: data.suggestion,
          category: data.category,
          errorCode: data.errorCode
        };
        setErrorDetails(details);
        setShowTechnicalDetails(true);
        return;
      }

      // Login exitoso
      router.push(redirectUrl);
      router.refresh();
    } catch (err: any) {
      setErrorDetails({
        message: 'No fue posible comunicarse con el servidor',
        detail: err?.message || String(err),
        category: 'SERVER',
        suggestion: '1. Verifique que el servidor web Next.js esté en ejecución en el puerto 3002.\n2. Compruebe la conectividad de red local.'
      });
      setShowTechnicalDetails(true);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-slate-900 via-blue-950 to-slate-900 flex items-center justify-center p-4">
      <div className="w-full max-w-md bg-white/95 backdrop-blur-md rounded-3xl shadow-2xl border border-white/20 p-8 transition-all">
        
        {/* Encabezado con Logo */}
        <div className="text-center mb-6">
          <div className="inline-flex items-center justify-center w-16 h-16 rounded-2xl bg-blue-600 text-white mb-4 shadow-lg shadow-blue-500/30">
            <Building2 className="w-8 h-8" />
          </div>
          <h1 className="text-2xl font-bold text-slate-900 tracking-tight">Korex Contabilidad</h1>
          <p className="text-xs text-slate-500 mt-1">Sistema de Contabilidad General para Colombia (NIIF / PUC)</p>
          <div className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-emerald-50 text-emerald-700 text-xs font-semibold mt-3 border border-emerald-200">
            <ShieldCheck className="w-3.5 h-3.5" />
            <span>Licencia Oficial Activa (KOR1)</span>
          </div>
        </div>

        {/* Notificación Detallada de Error */}
        {errorDetails && (
          <div className="mb-6 bg-rose-50 border border-rose-200 rounded-2xl p-4 text-left space-y-2.5 shadow-sm animate-shake">
            <div className="flex items-start gap-2.5">
              <div className="p-1.5 bg-rose-100 text-rose-600 rounded-lg shrink-0 mt-0.5">
                <AlertTriangle className="w-4 h-4" />
              </div>
              <div className="flex-1 min-w-0">
                <div className="flex items-center justify-between gap-2">
                  <h4 className="text-xs font-bold text-rose-800 leading-tight">
                    {errorDetails.message}
                  </h4>
                  {errorDetails.category && (
                    <span className="text-[9px] uppercase font-bold tracking-wider px-2 py-0.5 bg-rose-200/70 text-rose-800 rounded-full shrink-0">
                      {errorDetails.category === 'DATABASE' ? 'BD / SQL' : errorDetails.category}
                    </span>
                  )}
                </div>

                {errorDetails.suggestion && (
                  <div className="mt-2 text-[11px] text-slate-700 bg-white/80 p-2.5 rounded-xl border border-rose-200/60 space-y-1">
                    <div className="font-bold text-amber-700 flex items-center gap-1.5 text-[10px] uppercase tracking-wider">
                      <HelpCircle className="w-3 h-3" />
                      Pasos sugeridos para solucionar:
                    </div>
                    <div className="whitespace-pre-line leading-relaxed font-mono text-[10px] text-slate-600">
                      {errorDetails.suggestion}
                    </div>
                  </div>
                )}

                {errorDetails.detail && (
                  <div className="mt-2">
                    <button
                      type="button"
                      onClick={() => setShowTechnicalDetails(!showTechnicalDetails)}
                      className="text-[10px] text-rose-600 hover:text-rose-800 flex items-center gap-1 font-semibold transition-colors"
                    >
                      {showTechnicalDetails ? <ChevronUp className="w-3 h-3" /> : <ChevronDown className="w-3 h-3" />}
                      {showTechnicalDetails ? 'Ocultar detalle técnico' : 'Ver detalle técnico del error'}
                    </button>

                    {showTechnicalDetails && (
                      <pre className="mt-1.5 p-2 bg-slate-900 text-rose-300 text-[9px] font-mono rounded-lg overflow-x-auto border border-rose-900/40 break-all whitespace-pre-wrap max-h-32">
                        {errorDetails.detail}
                        {errorDetails.errorCode ? `\n[Código Error: ${errorDetails.errorCode}]` : ''}
                      </pre>
                    )}
                  </div>
                )}
              </div>
            </div>
          </div>
        )}

        {/* Formulario */}
        <form onSubmit={handleLogin} className="space-y-4">
          <div>
            <label className="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-1.5">
              Correo Electrónico
            </label>
            <div className="relative">
              <Mail className="w-4 h-4 text-slate-400 absolute left-3.5 top-1/2 -translate-y-1/2" />
              <input
                type="email"
                required
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                placeholder="admin@korex.com.co"
                className="w-full pl-10 pr-4 py-2.5 bg-slate-50 border border-slate-200 rounded-xl text-xs focus:outline-none focus:ring-2 focus:ring-blue-500 focus:bg-white transition-all text-slate-800 font-medium"
              />
            </div>
          </div>

          <div>
            <label className="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-1.5">
              Contraseña
            </label>
            <div className="relative">
              <Lock className="w-4 h-4 text-slate-400 absolute left-3.5 top-1/2 -translate-y-1/2" />
              <input
                type="password"
                required
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                placeholder="••••••••"
                className="w-full pl-10 pr-4 py-2.5 bg-slate-50 border border-slate-200 rounded-xl text-xs focus:outline-none focus:ring-2 focus:ring-blue-500 focus:bg-white transition-all text-slate-800 font-medium"
              />
            </div>
          </div>

          <button
            type="submit"
            disabled={loading}
            className="w-full py-3 px-4 bg-blue-600 hover:bg-blue-700 active:bg-blue-800 text-white text-xs font-bold rounded-xl shadow-lg shadow-blue-500/25 transition-all flex items-center justify-center gap-2 group cursor-pointer disabled:opacity-50 mt-2"
          >
            {loading ? (
              <>
                <RefreshCw className="w-4 h-4 animate-spin" />
                <span>Validando credenciales...</span>
              </>
            ) : (
              <>
                <span>Ingresar al Sistema</span>
                <ArrowRight className="w-4 h-4 group-hover:translate-x-1 transition-transform" />
              </>
            )}
          </button>
        </form>

        {/* Credenciales de Demostración */}
        <div className="mt-6 pt-5 border-t border-slate-100 text-center text-xs text-slate-500">
          <p className="font-bold text-slate-700 mb-1">Credenciales por Defecto del Sistema:</p>
          <p>Usuario: <code className="text-blue-600 bg-blue-50 px-2 py-0.5 rounded font-mono font-bold">admin@korex.com.co</code></p>
          <p className="mt-1">Contraseña: <code className="text-blue-600 bg-blue-50 px-2 py-0.5 rounded font-mono font-bold">Admin123*</code></p>
        </div>

      </div>
    </div>
  );
}
