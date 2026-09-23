'use client';

import React, { useState, useEffect } from 'react';
import {
  Building2,
  Search,
  Plus,
  RefreshCw,
  Play,
  CheckCircle2,
  Layers,
  Trash2,
  DollarSign,
  Calendar,
  X
} from 'lucide-react';

interface FixedAsset {
  id: string;
  code: string;
  name: string;
  category: string;
  purchaseDate: string;
  purchaseCost: number;
  salvageValue: number;
  usefulLifeMonths: number;
  accumulatedDepreciation: number;
  netBookValue: number;
  status: 'ACTIVE' | 'DISPOSED' | 'FULLY_DEPRECIATED';
}

export default function FixedAssetsPage() {
  const [assets, setAssets] = useState<FixedAsset[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState('');
  const [showModal, setShowModal] = useState(false);
  const [runningDepreciation, setRunningDepreciation] = useState(false);

  // Form State
  const [formData, setFormData] = useState({
    code: '',
    name: '',
    category: 'MAQUINARIA_EQUIPO',
    purchaseDate: new Date().toISOString().split('T')[0],
    purchaseCost: '',
    salvageValue: '0',
    usefulLifeMonths: '120',
    assetAccountId: '',
    depreciationAccountId: '',
    expenseAccountId: ''
  });

  const loadData = async () => {
    try {
      setLoading(true);
      const res = await fetch('/api/fixed-assets');
      if (res.ok) {
        const json = await res.json();
        setAssets(json.data || json || []);
      }
    } catch (e) {
      console.error('Error cargando activos fijos:', e);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadData();
  }, []);

  const totalCost = assets.reduce((acc, a) => acc + (Number(a.purchaseCost) || 0), 0);
  const totalDepr = assets.reduce((acc, a) => acc + (Number(a.accumulatedDepreciation) || 0), 0);
  const totalNet = assets.reduce((acc, a) => acc + (Number(a.netBookValue) || 0), 0);

  const handleRunDepreciation = async () => {
    if (!confirm('¿Desea ejecutar la liquidación mensual de depreciación en línea recta para todos los activos activos?')) return;
    try {
      setRunningDepreciation(true);
      const res = await fetch('/api/fixed-assets/depreciation-run', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          periodYear: new Date().getFullYear(),
          periodMonth: new Date().getMonth() + 1
        })
      });

      if (res.ok) {
        alert('¡Depreciación mensual calculada y causada exitosamente en comprobante contable!');
        loadData();
      } else {
        const err = await res.json();
        alert(`Error al ejecutar depreciación: ${err.message || err.error}`);
      }
    } catch (e) {
      alert('Error de conexión');
    } finally {
      setRunningDepreciation(false);
    }
  };

  const handleCreateAsset = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
      const res = await fetch('/api/fixed-assets', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          ...formData,
          purchaseCost: parseFloat(formData.purchaseCost) || 0,
          salvageValue: parseFloat(formData.salvageValue) || 0,
          usefulLifeMonths: parseInt(formData.usefulLifeMonths) || 120
        })
      });

      if (res.ok) {
        setShowModal(false);
        loadData();
      } else {
        const err = await res.json();
        alert(`Error al registrar activo: ${err.message || err.error}`);
      }
    } catch (e) {
      alert('Error de conexión');
    }
  };

  const filteredAssets = assets.filter((a) => {
    const code = (a.code || '').toLowerCase();
    const name = (a.name || '').toLowerCase();
    return code.includes(searchTerm.toLowerCase()) || name.includes(searchTerm.toLowerCase());
  });

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 bg-white p-6 rounded-2xl border border-slate-200 shadow-sm">
        <div>
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-xl bg-amber-100 text-amber-600 flex items-center justify-center font-bold">
              <Building2 className="w-5 h-5" />
            </div>
            <div>
              <h1 className="text-xl font-bold text-slate-900">Activos Fijos y Depreciación NIIF</h1>
              <p className="text-xs text-slate-500">Propiedad, Planta y Equipo (Grupo 15), vida útil, valor residual y motor de depreciación</p>
            </div>
          </div>
        </div>
        <div className="flex items-center gap-3">
          <button
            onClick={loadData}
            className="p-2.5 rounded-xl border border-slate-200 text-slate-600 hover:bg-slate-50 transition-colors"
            title="Refrescar"
          >
            <RefreshCw className={`w-4 h-4 ${loading ? 'animate-spin' : ''}`} />
          </button>
          <button
            onClick={handleRunDepreciation}
            disabled={runningDepreciation}
            className="flex items-center gap-2 px-4 py-2.5 rounded-xl bg-emerald-600 text-white text-xs font-semibold hover:bg-emerald-700 shadow-sm shadow-emerald-500/20 transition-all"
          >
            <Play className={`w-4 h-4 ${runningDepreciation ? 'animate-spin' : ''}`} />
            <span>Ejecutar Depreciación Mensual</span>
          </button>
          <button
            onClick={() => setShowModal(true)}
            className="flex items-center gap-2 px-4 py-2.5 rounded-xl bg-blue-600 text-white text-xs font-semibold hover:bg-blue-700 shadow-sm shadow-blue-500/20 transition-all"
          >
            <Plus className="w-4 h-4" />
            <span>+ Nuevo Activo</span>
          </button>
        </div>
      </div>

      {/* KPI Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
        <div className="bg-white p-5 rounded-2xl border border-slate-200 shadow-sm flex items-center justify-between">
          <div>
            <p className="text-[11px] font-semibold text-slate-500 uppercase tracking-wider">Costo Histórico Total</p>
            <p className="text-2xl font-bold text-slate-900 mt-1 font-mono">
              ${totalCost.toLocaleString('es-CO', { minimumFractionDigits: 2 })}
            </p>
            <p className="text-[11px] text-slate-400 mt-0.5">{assets.length} Activos Inventariados</p>
          </div>
          <div className="w-11 h-11 rounded-xl bg-blue-50 text-blue-600 flex items-center justify-center font-bold">
            <Building2 className="w-6 h-6" />
          </div>
        </div>

        <div className="bg-white p-5 rounded-2xl border border-slate-200 shadow-sm flex items-center justify-between">
          <div>
            <p className="text-[11px] font-semibold text-slate-500 uppercase tracking-wider">Depreciación Acumulada</p>
            <p className="text-2xl font-bold text-rose-600 mt-1 font-mono">
              ${totalDepr.toLocaleString('es-CO', { minimumFractionDigits: 2 })}
            </p>
            <p className="text-[11px] text-slate-400 mt-0.5">Cuenta 1592 - NIIF</p>
          </div>
          <div className="w-11 h-11 rounded-xl bg-rose-50 text-rose-600 flex items-center justify-center font-bold">
            <DollarSign className="w-6 h-6" />
          </div>
        </div>

        <div className="bg-white p-5 rounded-2xl border border-slate-200 shadow-sm flex items-center justify-between">
          <div>
            <p className="text-[11px] font-semibold text-slate-500 uppercase tracking-wider">Valor Neto en Libros</p>
            <p className="text-2xl font-bold text-emerald-700 mt-1 font-mono">
              ${totalNet.toLocaleString('es-CO', { minimumFractionDigits: 2 })}
            </p>
            <p className="text-[11px] text-slate-400 mt-0.5">Costo - Depreciación Acumulada</p>
          </div>
          <div className="w-11 h-11 rounded-xl bg-emerald-50 text-emerald-600 flex items-center justify-center font-bold">
            <CheckCircle2 className="w-6 h-6" />
          </div>
        </div>
      </div>

      {/* Assets Table */}
      <div className="bg-white rounded-2xl border border-slate-200 shadow-sm overflow-hidden space-y-4">
        <div className="p-4 border-b border-slate-100">
          <div className="relative">
            <Search className="w-4 h-4 text-slate-400 absolute left-3.5 top-1/2 -translate-y-1/2" />
            <input
              type="text"
              placeholder="Buscar por placa, código o descripción de activo..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              className="w-full pl-10 pr-4 py-2 bg-slate-50 border border-slate-200 rounded-xl text-xs text-slate-900 focus:outline-none focus:ring-2 focus:ring-blue-500"
            />
          </div>
        </div>

        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse">
            <thead>
              <tr className="bg-slate-50 border-b border-slate-200 text-[11px] font-bold text-slate-500 uppercase tracking-wider">
                <th className="py-3 px-4">Código / Placa</th>
                <th className="py-3 px-4">Descripción del Activo</th>
                <th className="py-3 px-4">Categoría</th>
                <th className="py-3 px-4">Compra</th>
                <th className="py-3 px-4 text-right">Costo ($)</th>
                <th className="py-3 px-4 text-right">Depr. Acumulada ($)</th>
                <th className="py-3 px-4 text-right">Neto en Libros ($)</th>
                <th className="py-3 px-4 text-center">Estado</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100 text-xs text-slate-700">
              {filteredAssets.length === 0 ? (
                <tr>
                  <td colSpan={8} className="py-12 text-center text-slate-400">
                    <Building2 className="w-10 h-10 mx-auto mb-2 text-slate-300" />
                    <p className="font-semibold">No se encontraron activos fijos registrados</p>
                  </td>
                </tr>
              ) : (
                filteredAssets.map((asset) => (
                  <tr key={asset.id} className="hover:bg-slate-50/80">
                    <td className="py-3 px-4 font-mono font-bold text-slate-900">
                      {asset.code}
                    </td>
                    <td className="py-3 px-4 font-semibold text-slate-800">
                      {asset.name}
                    </td>
                    <td className="py-3 px-4">
                      <span className="px-2 py-0.5 rounded text-[10px] font-bold bg-slate-100 text-slate-700">
                        {asset.category}
                      </span>
                    </td>
                    <td className="py-3 px-4 font-mono text-slate-600">
                      {asset.purchaseDate ? new Date(asset.purchaseDate).toLocaleDateString('es-CO') : '-'}
                    </td>
                    <td className="py-3 px-4 text-right font-mono font-bold text-slate-900">
                      ${Number(asset.purchaseCost || 0).toLocaleString('es-CO', { minimumFractionDigits: 2 })}
                    </td>
                    <td className="py-3 px-4 text-right font-mono font-bold text-rose-600">
                      ${Number(asset.accumulatedDepreciation || 0).toLocaleString('es-CO', { minimumFractionDigits: 2 })}
                    </td>
                    <td className="py-3 px-4 text-right font-mono font-bold text-emerald-700">
                      ${Number(asset.netBookValue || 0).toLocaleString('es-CO', { minimumFractionDigits: 2 })}
                    </td>
                    <td className="py-3 px-4 text-center">
                      <span className={`inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-[10px] font-bold ${
                        asset.status === 'ACTIVE'
                          ? 'bg-emerald-50 text-emerald-700'
                          : 'bg-slate-100 text-slate-500'
                      }`}>
                        {asset.status === 'ACTIVE' ? 'Activo' : 'Depreciado'}
                      </span>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>

      {/* Modal Nuevo Activo */}
      {showModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-900/60 backdrop-blur-sm">
          <div className="bg-white w-full max-w-lg rounded-2xl border border-slate-200 shadow-2xl p-6 space-y-4">
            <div className="flex items-center justify-between border-b border-slate-100 pb-3">
              <h3 className="text-base font-bold text-slate-900">Registrar Nuevo Activo Fijo</h3>
              <button onClick={() => setShowModal(false)} className="text-slate-400 hover:text-slate-600">
                <X className="w-5 h-5" />
              </button>
            </div>

            <form onSubmit={handleCreateAsset} className="space-y-4">
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-xs font-bold text-slate-700 mb-1">Código / Placa</label>
                  <input
                    type="text"
                    required
                    placeholder="ACT-001"
                    value={formData.code}
                    onChange={(e) => setFormData({ ...formData, code: e.target.value })}
                    className="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-xl text-xs font-mono text-slate-900"
                  />
                </div>
                <div>
                  <label className="block text-xs font-bold text-slate-700 mb-1">Categoría NIIF</label>
                  <select
                    value={formData.category}
                    onChange={(e) => setFormData({ ...formData, category: e.target.value })}
                    className="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-xl text-xs text-slate-900"
                  >
                    <option value="MAQUINARIA_EQUIPO">Maquinaria y Equipo (10 años)</option>
                    <option value="EQUIPO_COMPUTO">Equipo de Cómputo (5 años)</option>
                    <option value="VEHICULOS">Vehículos y Transporte (10 años)</option>
                    <option value="MUEBLES_ENSERES">Muebles y Enseres (10 años)</option>
                    <option value="EDIFICACIONES">Edificaciones (20 años)</option>
                  </select>
                </div>
              </div>

              <div>
                <label className="block text-xs font-bold text-slate-700 mb-1">Nombre / Descripción del Activo</label>
                <input
                  type="text"
                  required
                  placeholder="Ej. Servidor Dell PowerEdge R750"
                  value={formData.name}
                  onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                  className="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-xl text-xs text-slate-900"
                />
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-xs font-bold text-slate-700 mb-1">Costo de Adquisición ($)</label>
                  <input
                    type="number"
                    step="0.01"
                    required
                    placeholder="0.00"
                    value={formData.purchaseCost}
                    onChange={(e) => setFormData({ ...formData, purchaseCost: e.target.value })}
                    className="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-xl text-xs font-mono font-bold text-slate-900"
                  />
                </div>
                <div>
                  <label className="block text-xs font-bold text-slate-700 mb-1">Vida Útil (Meses)</label>
                  <input
                    type="number"
                    required
                    placeholder="120"
                    value={formData.usefulLifeMonths}
                    onChange={(e) => setFormData({ ...formData, usefulLifeMonths: e.target.value })}
                    className="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-xl text-xs font-mono text-slate-900"
                  />
                </div>
              </div>

              <div className="flex justify-end gap-2 pt-2 border-t border-slate-100">
                <button
                  type="button"
                  onClick={() => setShowModal(false)}
                  className="px-4 py-2 text-xs font-semibold text-slate-600 hover:bg-slate-100 rounded-xl"
                >
                  Cancelar
                </button>
                <button
                  type="submit"
                  className="px-4 py-2 text-xs font-semibold bg-blue-600 text-white rounded-xl hover:bg-blue-700 shadow-sm"
                >
                  Registrar Activo
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
