'use client';

import React, { useState, useEffect } from 'react';
import {
  Percent,
  Calendar,
  Download,
  FileSpreadsheet,
  FileCode,
  RefreshCw,
  CheckCircle2,
  AlertCircle,
  Layers,
  DollarSign
} from 'lucide-react';

export default function TaxesPage() {
  const [activeTab, setActiveTab] = useState<'VAT_300' | 'WITHHOLDING_350' | 'EXOGENA_DIAN'>('VAT_300');
  const [periodYear, setPeriodYear] = useState('2026');
  const [periodBimester, setPeriodBimester] = useState('1');
  const [periodMonth, setPeriodMonth] = useState('1');
  const [taxData, setTaxData] = useState<any>(null);
  const [loading, setLoading] = useState(false);

  const loadTaxDeclaration = async () => {
    try {
      setLoading(true);
      let endpoint = `/api/taxes/vat-declaration?year=${periodYear}&bimester=${periodBimester}`;
      if (activeTab === 'WITHHOLDING_350') {
        endpoint = `/api/taxes/withholding-declaration?year=${periodYear}&month=${periodMonth}`;
      }

      const res = await fetch(endpoint);
      if (res.ok) {
        const json = await res.json();
        setTaxData(json.data || json || null);
      }
    } catch (e) {
      console.error('Error cargando declaración tributaria:', e);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    if (activeTab !== 'EXOGENA_DIAN') {
      loadTaxDeclaration();
    }
  }, [activeTab, periodYear, periodBimester, periodMonth]);

  const handleDownloadExogena = async (formatNumber: string) => {
    try {
      const res = await fetch(`/api/interfaces/export/exogena-xml?year=${periodYear}&format=${formatNumber}`);
      if (res.ok) {
        const blob = await res.blob();
        const url = window.URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = `DIAN_Formato_${formatNumber}_v${periodYear}.xml`;
        a.click();
      } else {
        alert('Error al generar XML de Exógena DIAN');
      }
    } catch (e) {
      alert('Error al descargar archivo');
    }
  };

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 bg-white p-6 rounded-2xl border border-slate-200 shadow-sm">
        <div>
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-xl bg-purple-100 text-purple-600 flex items-center justify-center font-bold">
              <Percent className="w-5 h-5" />
            </div>
            <div>
              <h1 className="text-xl font-bold text-slate-900">Módulo Tributario y DIAN</h1>
              <p className="text-xs text-slate-500">Liquidación Formulario 300 (IVA), Formulario 350 (Retención en la Fuente) y Medios Magnéticos Exógena</p>
            </div>
          </div>
        </div>
        <div className="flex items-center gap-3">
          <button
            onClick={loadTaxDeclaration}
            className="flex items-center gap-2 px-4 py-2.5 rounded-xl bg-purple-600 text-white text-xs font-semibold hover:bg-purple-700 shadow-sm transition-all"
          >
            <RefreshCw className={`w-4 h-4 ${loading ? 'animate-spin' : ''}`} />
            <span>Recalcular Impuestos</span>
          </button>
        </div>
      </div>

      {/* Tabs */}
      <div className="flex items-center gap-2 border-b border-slate-200 pb-2">
        <button
          onClick={() => setActiveTab('VAT_300')}
          className={`px-4 py-2 rounded-xl text-xs font-bold transition-all ${
            activeTab === 'VAT_300'
              ? 'bg-purple-600 text-white shadow-sm'
              : 'bg-white text-slate-600 hover:bg-slate-100 border border-slate-200'
          }`}
        >
          Formulario 300 - Declaración de IVA
        </button>
        <button
          onClick={() => setActiveTab('WITHHOLDING_350')}
          className={`px-4 py-2 rounded-xl text-xs font-bold transition-all ${
            activeTab === 'WITHHOLDING_350'
              ? 'bg-purple-600 text-white shadow-sm'
              : 'bg-white text-slate-600 hover:bg-slate-100 border border-slate-200'
          }`}
        >
          Formulario 350 - Retención en la Fuente
        </button>
        <button
          onClick={() => setActiveTab('EXOGENA_DIAN')}
          className={`px-4 py-2 rounded-xl text-xs font-bold transition-all ${
            activeTab === 'EXOGENA_DIAN'
              ? 'bg-purple-600 text-white shadow-sm'
              : 'bg-white text-slate-600 hover:bg-slate-100 border border-slate-200'
          }`}
        >
          Medios Magnéticos (Exógena DIAN)
        </button>
      </div>

      {/* Formulario 300 IVA */}
      {activeTab === 'VAT_300' && (
        <div className="bg-white p-8 rounded-2xl border border-slate-200 shadow-sm space-y-6">
          <div className="flex items-center justify-between pb-4 border-b border-slate-200">
            <div>
              <h3 className="text-base font-bold text-slate-900">Borrador Oficial Formulario 300 (IVA Bimestral/Cuatrimestral)</h3>
              <p className="text-xs text-slate-500">Impuesto sobre las Ventas por Pagar - DIAN Colombia</p>
            </div>
            <div className="flex items-center gap-3">
              <select
                value={periodBimester}
                onChange={(e) => setPeriodBimester(e.target.value)}
                className="px-3 py-1.5 bg-slate-50 border border-slate-200 rounded-xl text-xs font-semibold text-slate-800"
              >
                <option value="1">Bimestre 1 (Ene - Feb)</option>
                <option value="2">Bimestre 2 (Mar - Abr)</option>
                <option value="3">Bimestre 3 (May - Jun)</option>
                <option value="4">Bimestre 4 (Jul - Ago)</option>
                <option value="5">Bimestre 5 (Sep - Oct)</option>
                <option value="6">Bimestre 6 (Nov - Dic)</option>
              </select>
            </div>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            <div className="p-5 rounded-2xl bg-slate-50 border border-slate-200 space-y-3">
              <h4 className="text-xs font-bold text-slate-800 uppercase">IVA Generado en Ventas (Casilla 59)</h4>
              <p className="text-2xl font-bold font-mono text-purple-700">
                ${Number(taxData?.generatedVat || 0).toLocaleString('es-CO', { minimumFractionDigits: 2 })}
              </p>
              <p className="text-[11px] text-slate-500">Base gravable de ingresos: ${Number(taxData?.taxableSalesBase || 0).toLocaleString('es-CO')}</p>
            </div>

            <div className="p-5 rounded-2xl bg-slate-50 border border-slate-200 space-y-3">
              <h4 className="text-xs font-bold text-slate-800 uppercase">IVA Descontable en Compras (Casilla 76)</h4>
              <p className="text-2xl font-bold font-mono text-emerald-600">
                ${Number(taxData?.deductibleVat || 0).toLocaleString('es-CO', { minimumFractionDigits: 2 })}
              </p>
              <p className="text-[11px] text-slate-500">Base gravable de compras: ${Number(taxData?.taxablePurchasesBase || 0).toLocaleString('es-CO')}</p>
            </div>
          </div>

          <div className="p-6 rounded-2xl bg-purple-50 border border-purple-200 flex items-center justify-between">
            <div>
              <span className="text-xs font-bold text-purple-900 uppercase block">SALDO A PAGAR / (SALDO A FAVOR) - CASILLA 83</span>
              <span className="text-3xl font-bold font-mono text-purple-800 mt-1 block">
                ${(Number(taxData?.generatedVat || 0) - Number(taxData?.deductibleVat || 0)).toLocaleString('es-CO', { minimumFractionDigits: 2 })}
              </span>
            </div>
            <CheckCircle2 className="w-10 h-10 text-purple-600" />
          </div>
        </div>
      )}

      {/* Formulario 350 Retefuente */}
      {activeTab === 'WITHHOLDING_350' && (
        <div className="bg-white p-8 rounded-2xl border border-slate-200 shadow-sm space-y-6">
          <div className="flex items-center justify-between pb-4 border-b border-slate-200">
            <div>
              <h3 className="text-base font-bold text-slate-900">Borrador Oficial Formulario 350 (Retención en la Fuente Mensual)</h3>
              <p className="text-xs text-slate-500">Retenciones practicadas por Renta, IVA (ReteIVA) e ICA</p>
            </div>
            <div className="flex items-center gap-3">
              <select
                value={periodMonth}
                onChange={(e) => setPeriodMonth(e.target.value)}
                className="px-3 py-1.5 bg-slate-50 border border-slate-200 rounded-xl text-xs font-semibold text-slate-800"
              >
                <option value="1">Mes 01 - Enero</option>
                <option value="2">Mes 02 - Febrero</option>
                <option value="3">Mes 03 - Marzo</option>
                <option value="4">Mes 04 - Abril</option>
                <option value="5">Mes 05 - Mayo</option>
                <option value="6">Mes 06 - Junio</option>
                <option value="7">Mes 07 - Julio</option>
                <option value="8">Mes 08 - Agosto</option>
                <option value="9">Mes 09 - Septiembre</option>
                <option value="10">Mes 10 - Octubre</option>
                <option value="11">Mes 11 - Noviembre</option>
                <option value="12">Mes 12 - Diciembre</option>
              </select>
            </div>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            <div className="p-4 rounded-xl bg-slate-50 border border-slate-200">
              <span className="text-[11px] font-bold text-slate-500 uppercase block">Renta - Honorarios y Servicios</span>
              <span className="text-xl font-bold font-mono text-slate-900 mt-1 block">
                ${Number(taxData?.withholdingServices || 0).toLocaleString('es-CO', { minimumFractionDigits: 2 })}
              </span>
            </div>

            <div className="p-4 rounded-xl bg-slate-50 border border-slate-200">
              <span className="text-[11px] font-bold text-slate-500 uppercase block">Renta - Compras Generales</span>
              <span className="text-xl font-bold font-mono text-slate-900 mt-1 block">
                ${Number(taxData?.withholdingPurchases || 0).toLocaleString('es-CO', { minimumFractionDigits: 2 })}
              </span>
            </div>

            <div className="p-4 rounded-xl bg-slate-50 border border-slate-200">
              <span className="text-[11px] font-bold text-slate-500 uppercase block">ReteIVA Practicado</span>
              <span className="text-xl font-bold font-mono text-slate-900 mt-1 block">
                ${Number(taxData?.withholdingVat || 0).toLocaleString('es-CO', { minimumFractionDigits: 2 })}
              </span>
            </div>
          </div>

          <div className="p-6 rounded-2xl bg-indigo-50 border border-indigo-200 flex items-center justify-between">
            <div>
              <span className="text-xs font-bold text-indigo-900 uppercase block">TOTAL RETENCIONES A PAGAR (CASILLA 85)</span>
              <span className="text-3xl font-bold font-mono text-indigo-800 mt-1 block">
                ${Number(taxData?.totalWithholding || 0).toLocaleString('es-CO', { minimumFractionDigits: 2 })}
              </span>
            </div>
            <CheckCircle2 className="w-10 h-10 text-indigo-600" />
          </div>
        </div>
      )}

      {/* Exógena DIAN */}
      {activeTab === 'EXOGENA_DIAN' && (
        <div className="bg-white p-8 rounded-2xl border border-slate-200 shadow-sm space-y-6">
          <div>
            <h3 className="text-base font-bold text-slate-900">Formatos Oficiales de Información Exógena DIAN</h3>
            <p className="text-xs text-slate-500">Generación y exportación de archivos XML y prevalidador DIAN por conceptos y terceros</p>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div className="p-5 rounded-2xl bg-slate-50 border border-slate-200 flex items-center justify-between">
              <div>
                <span className="font-bold text-sm text-slate-900 block">Formato 1001 (Versión 10)</span>
                <p className="text-xs text-slate-500">Pagos o abonos en cuenta y retenciones practicadas</p>
              </div>
              <button
                onClick={() => handleDownloadExogena('1001')}
                className="flex items-center gap-1.5 px-3.5 py-2 rounded-xl bg-purple-600 text-white text-xs font-semibold hover:bg-purple-700 shadow-sm"
              >
                <Download className="w-4 h-4" />
                <span>XML 1001</span>
              </button>
            </div>

            <div className="p-5 rounded-2xl bg-slate-50 border border-slate-200 flex items-center justify-between">
              <div>
                <span className="font-bold text-sm text-slate-900 block">Formato 1007 (Versión 9)</span>
                <p className="text-xs text-slate-500">Ingresos propios recibidos en el año fiscal</p>
              </div>
              <button
                onClick={() => handleDownloadExogena('1007')}
                className="flex items-center gap-1.5 px-3.5 py-2 rounded-xl bg-purple-600 text-white text-xs font-semibold hover:bg-purple-700 shadow-sm"
              >
                <Download className="w-4 h-4" />
                <span>XML 1007</span>
              </button>
            </div>

            <div className="p-5 rounded-2xl bg-slate-50 border border-slate-200 flex items-center justify-between">
              <div>
                <span className="font-bold text-sm text-slate-900 block">Formato 1008 (Versión 7)</span>
                <p className="text-xs text-slate-500">Saldos de cuentas por cobrar (Deudores)</p>
              </div>
              <button
                onClick={() => handleDownloadExogena('1008')}
                className="flex items-center gap-1.5 px-3.5 py-2 rounded-xl bg-purple-600 text-white text-xs font-semibold hover:bg-purple-700 shadow-sm"
              >
                <Download className="w-4 h-4" />
                <span>XML 1008</span>
              </button>
            </div>

            <div className="p-5 rounded-2xl bg-slate-50 border border-slate-200 flex items-center justify-between">
              <div>
                <span className="font-bold text-sm text-slate-900 block">Formato 1009 (Versión 7)</span>
                <p className="text-xs text-slate-500">Saldos de cuentas por pagar (Pasivos)</p>
              </div>
              <button
                onClick={() => handleDownloadExogena('1009')}
                className="flex items-center gap-1.5 px-3.5 py-2 rounded-xl bg-purple-600 text-white text-xs font-semibold hover:bg-purple-700 shadow-sm"
              >
                <Download className="w-4 h-4" />
                <span>XML 1009</span>
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
