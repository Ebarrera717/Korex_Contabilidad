'use client';

import React, { useState, useEffect } from 'react';
import { ShieldAlert, KeyRound, CheckCircle2, AlertCircle, RefreshCw, Building, FileText, Building2 } from 'lucide-react';

export default function LicenciaExpiradaPage() {
    const [licenseKey, setLicenseKey] = useState('');
    const [clientName, setClientName] = useState('');
    const [nit, setNit] = useState('');
    const [loading, setLoading] = useState(false);
    const [checkingStatus, setCheckingStatus] = useState(true);
    const [isUnlicensed, setIsUnlicensed] = useState(false);
    const [statusMessage, setStatusMessage] = useState<{ type: 'success' | 'error'; text: string } | null>(null);

    useEffect(() => {
        fetch('/api/config/license')
            .then(res => res.json())
            .then(data => {
                if (data.clientName) setClientName(data.clientName);
                if (data.nit) setNit(data.nit);

                if (data.isLicensed && !data.isExpired && (data.status === 'ACTIVE' || data.status === 'WARNING')) {
                    window.location.replace('/dashboard');
                } else {
                    if (data.status === 'UNLICENSED' || !data.isLicensed) {
                        setIsUnlicensed(true);
                    }
                    setCheckingStatus(false);
                }
            })
            .catch(() => setCheckingStatus(false));
    }, []);

    const handleActivate = async (e: React.FormEvent) => {
        e.preventDefault();
        if (!licenseKey.trim()) {
            setStatusMessage({ type: 'error', text: 'Por favor ingrese la clave de licencia entregada por el proveedor.' });
            return;
        }

        setLoading(true);
        setStatusMessage(null);

        try {
            const res = await fetch('/api/config/license', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    licenseKey: licenseKey.trim(),
                    clientName: clientName.trim(),
                    nit: nit.trim()
                })
            });

            const data = await res.json();

            if (!res.ok) {
                throw new Error(data.message || 'Error al validar la clave de licencia');
            }

            setStatusMessage({
                type: 'success',
                text: `¡Licencia activada con éxito para ${data.license.client}! Válida hasta ${data.license.expirationDate}. Redirigiendo...`
            });

            setTimeout(() => {
                window.location.replace('/dashboard');
            }, 1200);
        } catch (err: any) {
            setStatusMessage({
                type: 'error',
                text: err.message || 'La clave de licencia ingresada es inválida o expiró.'
            });
        } finally {
            setLoading(false);
        }
    };

    if (checkingStatus) {
        return (
            <div className="min-h-screen bg-slate-900 text-slate-100 flex items-center justify-center p-4">
                <div className="flex items-center gap-3 text-slate-400 font-medium">
                    <RefreshCw className="w-6 h-6 animate-spin text-blue-500" />
                    <span>Verificando estado de licencia Korex...</span>
                </div>
            </div>
        );
    }

    return (
        <div className="min-h-screen bg-gradient-to-br from-slate-900 via-blue-950 to-slate-900 text-slate-100 flex items-center justify-center p-4">
            <div className="max-w-xl w-full bg-white text-slate-800 rounded-3xl shadow-2xl overflow-hidden p-8 space-y-6 border border-white/20">
                
                {/* Header Alerta */}
                <div className="text-center space-y-3">
                    <div className="mx-auto w-16 h-16 bg-rose-50 border border-rose-200 rounded-2xl flex items-center justify-center text-rose-600 shadow-lg shadow-rose-500/10">
                        <ShieldAlert className="w-8 h-8" />
                    </div>
                    <h1 className="text-2xl font-bold tracking-tight text-slate-900">
                        {isUnlicensed ? 'Licencia Requerida para Habilitar el Sistema' : 'Licencia del Sistema Expirada'}
                    </h1>
                    <p className="text-xs text-slate-500">
                        {isUnlicensed
                            ? 'Esta instalación de Korex Contabilidad requiere ingresar la Clave de Licencia inicial para activar el servicio.'
                            : 'El período de funcionamiento contratado para esta versión de Korex Contabilidad ha finalizado o requiere renovación.'
                        }
                    </p>
                </div>

                {/* Mensaje Informativo */}
                <div className="bg-slate-50 border border-slate-200 rounded-2xl p-4 text-xs text-slate-700 space-y-2">
                    <div className="flex items-center gap-2 font-bold text-blue-800">
                        <AlertCircle className="w-4 h-4 text-blue-600" />
                        <span>¿Cómo renovar el acceso a Korex Contabilidad?</span>
                    </div>
                    <p className="text-[11px] text-slate-600 leading-relaxed">
                        Solicite a su proveedor la nueva <strong>Clave de Licencia</strong> generada con el programa <code className="bg-white border border-slate-200 px-1.5 py-0.5 rounded text-blue-700 font-mono font-bold">GenerarLicencia.bat</code> y péguela a continuación.
                    </p>
                </div>

                {/* Formulario de Activación */}
                <form onSubmit={handleActivate} className="space-y-4">
                    <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
                        <div className="space-y-1.5">
                            <label className="text-xs font-bold text-slate-700 flex items-center gap-1.5">
                                <Building className="w-3.5 h-3.5 text-slate-400" />
                                <span>Empresa / Razón Social:</span>
                            </label>
                            <input
                                type="text"
                                value={clientName}
                                onChange={(e) => setClientName(e.target.value)}
                                placeholder="Ej: EMPRESA DEMO CONTABLE S.A.S."
                                className="w-full bg-slate-50 border border-slate-200 rounded-xl px-3 py-2 text-xs font-semibold text-slate-900 focus:outline-none focus:ring-2 focus:ring-blue-500"
                            />
                        </div>
                        <div className="space-y-1.5">
                            <label className="text-xs font-bold text-slate-700 flex items-center gap-1.5">
                                <FileText className="w-3.5 h-3.5 text-slate-400" />
                                <span>NIT / Cédula:</span>
                            </label>
                            <input
                                type="text"
                                value={nit}
                                onChange={(e) => setNit(e.target.value)}
                                placeholder="Ej: 900123456-8"
                                className="w-full bg-slate-50 border border-slate-200 rounded-xl px-3 py-2 text-xs font-semibold text-slate-900 focus:outline-none focus:ring-2 focus:ring-blue-500"
                            />
                        </div>
                    </div>

                    <div className="space-y-1.5">
                        <label className="text-xs font-bold text-slate-700 flex items-center gap-1.5">
                            <KeyRound className="w-3.5 h-3.5 text-slate-400" />
                            <span>Clave de Licencia (Token Cifrado KOR1):</span>
                        </label>
                        <textarea
                            value={licenseKey}
                            onChange={(e) => setLicenseKey(e.target.value)}
                            placeholder="KOR1.eyJjIjoi... (Pegue la clave completa entregada por el soporte)"
                            rows={3}
                            className="w-full bg-slate-50 border border-slate-200 rounded-xl p-3 text-xs font-mono font-bold text-emerald-700 focus:outline-none focus:ring-2 focus:ring-blue-500 resize-none"
                        />
                    </div>

                    {statusMessage && (
                        <div className={`p-3 rounded-xl text-xs font-bold flex items-start gap-2 ${
                            statusMessage.type === 'success'
                                ? 'bg-emerald-50 border border-emerald-200 text-emerald-800'
                                : 'bg-rose-50 border border-rose-200 text-rose-800'
                        }`}>
                            {statusMessage.type === 'success' ? (
                                <CheckCircle2 className="w-4 h-4 shrink-0 mt-0.5 text-emerald-600" />
                            ) : (
                                <AlertCircle className="w-4 h-4 shrink-0 mt-0.5 text-rose-600" />
                            )}
                            <span>{statusMessage.text}</span>
                        </div>
                    )}

                    <button
                        type="submit"
                        disabled={loading}
                        className="w-full bg-blue-600 hover:bg-blue-700 disabled:opacity-50 text-white font-bold py-2.5 px-4 rounded-xl text-xs flex items-center justify-center gap-2 shadow-lg shadow-blue-500/25 transition-all cursor-pointer"
                    >
                        {loading ? (
                            <>
                                <RefreshCw className="w-4 h-4 animate-spin" />
                                <span>Verificando y Activando...</span>
                            </>
                        ) : (
                            <>
                                <CheckCircle2 className="w-4 h-4" />
                                <span>Activar Licencia del Sistema</span>
                            </>
                        )}
                    </button>
                </form>

                {/* Footer Soporte */}
                <div className="text-center pt-2 text-[11px] text-slate-400 border-t border-slate-100">
                    Soporte Técnico Korex Contabilidad NIIF | Versión 2026
                </div>

            </div>
        </div>
    );
}
