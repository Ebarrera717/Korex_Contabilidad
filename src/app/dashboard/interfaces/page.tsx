'use client';

import React, { useState, useEffect } from 'react';
import {
  ArrowLeftRight,
  UploadCloud,
  FileSpreadsheet,
  Webhook,
  Download,
  RefreshCw,
  CheckCircle2,
  AlertCircle,
  Clock,
  Layers,
  FileText,
  Activity
} from 'lucide-react';

export default function InterfacesPage() {
  const [activeTab, setActiveTab] = useState<'IMPORT' | 'WEBHOOKS' | 'TEMPLATES'>('IMPORT');
  const [importType, setImportType] = useState<'JOURNAL_ENTRIES' | 'THIRD_PARTIES' | 'PUC'>('JOURNAL_ENTRIES');
  const [selectedFile, setSelectedFile] = useState<File | null>(null);
  const [uploading, setUploading] = useState(false);
  const [importResult, setImportResult] = useState<any>(null);
  const [webhookLogs, setWebhookLogs] = useState<any[]>([]);

  const loadWebhookLogs = async () => {
    try {
      const res = await fetch('/api/interfaces/external/transactions');
      if (res.ok) {
        const json = await res.json();
        setWebhookLogs(json.data || json || []);
      }
    } catch (e) {
      console.error('Error cargando logs:', e);
    }
  };

  useEffect(() => {
    if (activeTab === 'WEBHOOKS') {
      loadWebhookLogs();
    }
  }, [activeTab]);

  const handleImport = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!selectedFile) {
      alert('Por favor seleccione un archivo Excel o CSV.');
      return;
    }

    try {
      setUploading(true);
      setImportResult(null);
      const formData = new FormData();
      formData.append('file', selectedFile);

      let endpoint = '/api/interfaces/import/journal-entries';
      if (importType === 'THIRD_PARTIES') endpoint = '/api/interfaces/import/third-parties';
      if (importType === 'PUC') endpoint = '/api/interfaces/import/puc';

      const res = await fetch(endpoint, {
        method: 'POST',
        body: formData
      });

      const json = await res.json();
      setImportResult(json);
    } catch (e) {
      alert('Error al procesar el archivo');
    } finally {
      setUploading(false);
    }
  };

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 bg-white p-6 rounded-2xl border border-slate-200 shadow-sm">
        <div>
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-xl bg-blue-100 text-blue-600 flex items-center justify-center font-bold">
              <ArrowLeftRight className="w-5 h-5" />
            </div>
            <div>
              <h1 className="text-xl font-bold text-slate-900">Interfaces, Importación y API</h1>
              <p className="text-xs text-slate-500">Cargue masivo desde Excel, plantillas estándar y transacciones de integración Webhook / REST</p>
            </div>
          </div>
        </div>
      </div>

      {/* Tabs */}
      <div className="flex items-center gap-2 border-b border-slate-200 pb-2">
        <button
          onClick={() => setActiveTab('IMPORT')}
          className={`px-4 py-2 rounded-xl text-xs font-bold transition-all ${
            activeTab === 'IMPORT'
              ? 'bg-blue-600 text-white shadow-sm'
              : 'bg-white text-slate-600 hover:bg-slate-100 border border-slate-200'
          }`}
        >
          Cargue Masivo de Archivos (Excel/CSV)
        </button>
        <button
          onClick={() => setActiveTab('TEMPLATES')}
          className={`px-4 py-2 rounded-xl text-xs font-bold transition-all ${
            activeTab === 'TEMPLATES'
              ? 'bg-blue-600 text-white shadow-sm'
              : 'bg-white text-slate-600 hover:bg-slate-100 border border-slate-200'
          }`}
        >
          Descarga de Plantillas Oficiales
        </button>
        <button
          onClick={() => setActiveTab('WEBHOOKS')}
          className={`px-4 py-2 rounded-xl text-xs font-bold transition-all ${
            activeTab === 'WEBHOOKS'
              ? 'bg-blue-600 text-white shadow-sm'
              : 'bg-white text-slate-600 hover:bg-slate-100 border border-slate-200'
          }`}
        >
          Monitoreo de Integraciones y Webhooks
        </button>
      </div>

      {/* Tab 1: Cargue Masivo */}
      {activeTab === 'IMPORT' && (
        <div className="bg-white p-8 rounded-2xl border border-slate-200 shadow-sm space-y-6 max-w-2xl mx-auto">
          <div>
            <h3 className="text-base font-bold text-slate-900">Asistente de Importación de Datos</h3>
            <p className="text-xs text-slate-500">Seleccione el tipo de información y cargue su archivo</p>
          </div>

          <form onSubmit={handleImport} className="space-y-4">
            <div>
              <label className="block text-xs font-bold text-slate-700 mb-1">Tipo de Importación</label>
              <select
                value={importType}
                onChange={(e: any) => setImportType(e.target.value)}
                className="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-xl text-xs text-slate-900 focus:bg-white focus:ring-2 focus:ring-blue-500"
              >
                <option value="JOURNAL_ENTRIES">Comprobantes Contables y Movimientos</option>
                <option value="THIRD_PARTIES">Directorio de Terceros y Clientes</option>
                <option value="PUC">Catálogo del Plan Único de Cuentas (PUC)</option>
              </select>
            </div>

            <div className="border-2 border-dashed border-slate-200 rounded-2xl p-8 text-center space-y-3 hover:border-blue-400 transition-colors bg-slate-50">
              <UploadCloud className="w-10 h-10 text-slate-400 mx-auto" />
              <div>
                <p className="text-xs font-bold text-slate-700">Arrastre su archivo Excel (.xlsx) o CSV aquí</p>
                <p className="text-[11px] text-slate-400">o haga clic para seleccionarlo de su equipo</p>
              </div>
              <input
                type="file"
                accept=".xlsx,.xls,.csv"
                onChange={(e) => setSelectedFile(e.target.files?.[0] || null)}
                className="text-xs text-slate-500 file:mr-4 file:py-2 file:px-4 file:rounded-xl file:border-0 file:text-xs file:font-semibold file:bg-blue-50 file:text-blue-700 hover:file:bg-blue-100"
              />
            </div>

            <button
              type="submit"
              disabled={uploading || !selectedFile}
              className={`w-full py-2.5 rounded-xl text-xs font-semibold text-white transition-all ${
                uploading || !selectedFile
                  ? 'bg-slate-400 cursor-not-allowed opacity-60'
                  : 'bg-blue-600 hover:bg-blue-700 shadow-sm shadow-blue-500/20'
              }`}
            >
              {uploading ? 'Procesando e Importando...' : 'Iniciar Importación Masiva'}
            </button>
          </form>

          {/* Resultado de Importación */}
          {importResult && (
            <div className={`p-4 rounded-xl border ${importResult.success ? 'bg-emerald-50 border-emerald-200 text-emerald-900' : 'bg-rose-50 border-rose-200 text-rose-900'}`}>
              <div className="flex items-center gap-2 font-bold text-xs">
                {importResult.success ? <CheckCircle2 className="w-4 h-4 text-emerald-600" /> : <AlertCircle className="w-4 h-4 text-rose-600" />}
                <span>{importResult.message || (importResult.success ? '¡Importación completada exitosamente!' : 'Ocurrió un error en la importación')}</span>
              </div>
              {importResult.importedCount !== undefined && (
                <p className="text-[11px] mt-1">Registros importados correctamente: {importResult.importedCount}</p>
              )}
            </div>
          )}
        </div>
      )}

      {/* Tab 2: Plantillas */}
      {activeTab === 'TEMPLATES' && (
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          <div className="bg-white p-5 rounded-2xl border border-slate-200 shadow-sm space-y-3">
            <div className="w-10 h-10 rounded-xl bg-emerald-50 text-emerald-600 flex items-center justify-center font-bold">
              <FileSpreadsheet className="w-5 h-5" />
            </div>
            <h4 className="text-sm font-bold text-slate-900">Plantilla Comprobantes Contables</h4>
            <p className="text-xs text-slate-500">Estructura estándar con columnas: Fecha, Tipo, Cuenta, Tercero, Concepto, Débito, Crédito.</p>
            <a
              href="/api/interfaces/templates?type=journal-entries"
              download
              className="inline-flex items-center gap-1.5 px-3.5 py-2 rounded-xl bg-slate-100 text-slate-700 text-xs font-semibold hover:bg-slate-200 transition-colors"
            >
              <Download className="w-4 h-4" />
              <span>Descargar .xlsx</span>
            </a>
          </div>

          <div className="bg-white p-5 rounded-2xl border border-slate-200 shadow-sm space-y-3">
            <div className="w-10 h-10 rounded-xl bg-blue-50 text-blue-600 flex items-center justify-center font-bold">
              <FileSpreadsheet className="w-5 h-5" />
            </div>
            <h4 className="text-sm font-bold text-slate-900">Plantilla Directorio de Terceros</h4>
            <p className="text-xs text-slate-500">Estructura para NITs, nombres, tipo de persona, régimen tributario, dirección y contacto.</p>
            <a
              href="/api/interfaces/templates?type=third-parties"
              download
              className="inline-flex items-center gap-1.5 px-3.5 py-2 rounded-xl bg-slate-100 text-slate-700 text-xs font-semibold hover:bg-slate-200 transition-colors"
            >
              <Download className="w-4 h-4" />
              <span>Descargar .xlsx</span>
            </a>
          </div>

          <div className="bg-white p-5 rounded-2xl border border-slate-200 shadow-sm space-y-3">
            <div className="w-10 h-10 rounded-xl bg-purple-50 text-purple-600 flex items-center justify-center font-bold">
              <FileSpreadsheet className="w-5 h-5" />
            </div>
            <h4 className="text-sm font-bold text-slate-900">Plantilla Catálogo PUC</h4>
            <p className="text-xs text-slate-500">Estructura jerárquica para cargar cuentas de 1, 2, 4, 6 y 8 dígitos con naturaleza débito/crédito.</p>
            <a
              href="/api/interfaces/templates?type=puc"
              download
              className="inline-flex items-center gap-1.5 px-3.5 py-2 rounded-xl bg-slate-100 text-slate-700 text-xs font-semibold hover:bg-slate-200 transition-colors"
            >
              <Download className="w-4 h-4" />
              <span>Descargar .xlsx</span>
            </a>
          </div>
        </div>
      )}

      {/* Tab 3: Webhooks */}
      {activeTab === 'WEBHOOKS' && (
        <div className="bg-white rounded-2xl border border-slate-200 shadow-sm overflow-hidden space-y-4">
          <div className="p-6 border-b border-slate-100 flex items-center justify-between">
            <div>
              <h3 className="text-sm font-bold text-slate-900">Transacciones e Inyecciones API / Webhook</h3>
              <p className="text-xs text-slate-500">Historial en tiempo real de transacciones recibidas desde sistemas externos</p>
            </div>
            <button
              onClick={loadWebhookLogs}
              className="p-2 rounded-xl border border-slate-200 text-slate-600 hover:bg-slate-50"
            >
              <RefreshCw className="w-4 h-4" />
            </button>
          </div>

          <div className="overflow-x-auto">
            <table className="w-full text-left border-collapse text-xs">
              <thead>
                <tr className="bg-slate-50 border-b border-slate-200 text-[11px] font-bold text-slate-600 uppercase">
                  <th className="py-2.5 px-4">Fecha / Hora</th>
                  <th className="py-2.5 px-4">Origen</th>
                  <th className="py-2.5 px-4">Evento / Endpoint</th>
                  <th className="py-2.5 px-4">Estado</th>
                  <th className="py-2.5 px-4 text-right">Detalle</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100 text-slate-700">
                {webhookLogs.length === 0 ? (
                  <tr>
                    <td colSpan={5} className="py-12 text-center text-slate-400 font-sans">
                      <Activity className="w-8 h-8 mx-auto mb-2 text-slate-300" />
                      <p>No se han registrado transacciones externas recientes</p>
                    </td>
                  </tr>
                ) : (
                  webhookLogs.map((log: any, idx: number) => (
                    <tr key={idx} className="hover:bg-slate-50 font-mono">
                      <td className="py-2.5 px-4">{new Date(log.createdAt).toLocaleString('es-CO')}</td>
                      <td className="py-2.5 px-4 font-sans font-bold">{log.source || 'REST API'}</td>
                      <td className="py-2.5 px-4">{log.endpoint}</td>
                      <td className="py-2.5 px-4">
                        <span className="px-2 py-0.5 rounded text-[10px] font-bold bg-emerald-50 text-emerald-700">
                          {log.status || 'OK (200)'}
                        </span>
                      </td>
                      <td className="py-2.5 px-4 text-right font-sans text-[11px] text-slate-500">{log.message || 'Procesado'}</td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>
        </div>
      )}
    </div>
  );
}
