'use client';

import React, { useState, useEffect } from 'react';
import { BookOpen, Search, Plus, CheckCircle2, Filter, RefreshCw, X, Layers } from 'lucide-react';

interface Account {
  id?: string;
  code: string;
  name: string;
  level: number;
  nature: 'DEBIT' | 'CREDIT';
  isMovement: boolean;
  isActive?: boolean;
}

export default function PucPage() {
  const [accounts, setAccounts] = useState<Account[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState('');
  const [selectedClass, setSelectedClass] = useState('ALL');
  const [showModal, setShowModal] = useState(false);

  const [formData, setFormData] = useState({
    code: '',
    name: '',
    nature: 'DEBIT',
    isMovement: true
  });

  const loadAccounts = async () => {
    try {
      setLoading(true);
      const res = await fetch('/api/puc');
      if (res.ok) {
        const json = await res.json();
        const data = json.data || json || [];
        if (data.length > 0) {
          setAccounts(data);
          return;
        }
      }
      // Default initial PUC if empty
      setAccounts([
        { code: '1', name: 'ACTIVO', level: 1, nature: 'DEBIT', isMovement: false },
        { code: '11', name: 'DISPONIBLE', level: 2, nature: 'DEBIT', isMovement: false },
        { code: '1105', name: 'CAJA', level: 3, nature: 'DEBIT', isMovement: false },
        { code: '110505', name: 'CAJA GENERAL', level: 4, nature: 'DEBIT', isMovement: false },
        { code: '11050501', name: 'Caja Principal Moneda Local', level: 5, nature: 'DEBIT', isMovement: true },
        { code: '1110', name: 'BANCOS', level: 3, nature: 'DEBIT', isMovement: false },
        { code: '111005', name: 'MONEDA NACIONAL', level: 4, nature: 'DEBIT', isMovement: false },
        { code: '11100501', name: 'Banco Bancolombia Cta Cte 1234', level: 5, nature: 'DEBIT', isMovement: true },
        { code: '13', name: 'DEUDORES', level: 2, nature: 'DEBIT', isMovement: false },
        { code: '1305', name: 'CLIENTES', level: 3, nature: 'DEBIT', isMovement: false },
        { code: '130505', name: 'NACIONALES', level: 4, nature: 'DEBIT', isMovement: false },
        { code: '13050501', name: 'Clientes Nacionales - Bogotá', level: 5, nature: 'DEBIT', isMovement: true },
        { code: '2', name: 'PASIVO', level: 1, nature: 'CREDIT', isMovement: false },
        { code: '22', name: 'PROVEEDORES', level: 2, nature: 'CREDIT', isMovement: false },
        { code: '2205', name: 'NACIONALES', level: 3, nature: 'CREDIT', isMovement: false },
        { code: '22050501', name: 'Proveedores Nacionales - Medellín', level: 5, nature: 'CREDIT', isMovement: true },
        { code: '3', name: 'PATRIMONIO', level: 1, nature: 'CREDIT', isMovement: false },
        { code: '31', name: 'CAPITAL SOCIAL', level: 2, nature: 'CREDIT', isMovement: false },
        { code: '3115', name: 'APORTES SOCIALES', level: 3, nature: 'CREDIT', isMovement: false },
        { code: '4', name: 'INGRESOS', level: 1, nature: 'CREDIT', isMovement: false },
        { code: '4135', name: 'COMERCIO AL POR MAYOR Y MENOR', level: 3, nature: 'CREDIT', isMovement: false },
        { code: '5', name: 'GASTOS', level: 1, nature: 'DEBIT', isMovement: false },
        { code: '5105', name: 'GASTOS DE PERSONAL', level: 3, nature: 'DEBIT', isMovement: false }
      ]);
    } catch (e) {
      console.error('Error cargando PUC:', e);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadAccounts();
  }, []);

  const handleCreateAccount = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
      const res = await fetch('/api/puc', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(formData)
      });

      if (res.ok) {
        setShowModal(false);
        loadAccounts();
      } else {
        const err = await res.json();
        alert(`Error al guardar cuenta: ${err.message || err.error}`);
      }
    } catch (e) {
      alert('Error de conexión');
    }
  };

  const filtered = accounts.filter(acc => {
    const matchesSearch = acc.code.toLowerCase().includes(searchTerm.toLowerCase()) || acc.name.toLowerCase().includes(searchTerm.toLowerCase());
    const matchesClass = selectedClass === 'ALL' || acc.code.startsWith(selectedClass);
    return matchesSearch && matchesClass;
  });

  return (
    <div className="space-y-6">
      {/* Encabezado */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 bg-white p-6 rounded-2xl border border-slate-200 shadow-sm">
        <div>
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-xl bg-blue-100 text-blue-600 flex items-center justify-center font-bold">
              <BookOpen className="w-5 h-5" />
            </div>
            <div>
              <h1 className="text-xl font-bold text-slate-900">Plan Único de Cuentas (PUC)</h1>
              <p className="text-xs text-slate-500">Catálogo contable colombiano de 5 niveles bajo normas NIIF / NIC</p>
            </div>
          </div>
        </div>

        <div className="flex items-center gap-3">
          <button
            onClick={loadAccounts}
            className="p-2.5 rounded-xl border border-slate-200 text-slate-600 hover:bg-slate-50 transition-colors"
            title="Refrescar"
          >
            <RefreshCw className={`w-4 h-4 ${loading ? 'animate-spin' : ''}`} />
          </button>
          <button
            onClick={() => setShowModal(true)}
            className="flex items-center gap-2 px-4 py-2.5 bg-blue-600 hover:bg-blue-700 text-white text-xs font-semibold rounded-xl shadow-sm shadow-blue-500/20 transition-all"
          >
            <Plus className="w-4 h-4" />
            <span>+ Nueva Cuenta PUC</span>
          </button>
        </div>
      </div>

      {/* Filtros y Búsqueda */}
      <div className="bg-white p-4 rounded-2xl border border-slate-200 shadow-sm flex flex-col sm:flex-row items-center gap-3">
        <div className="relative flex-1 w-full">
          <Search className="w-4 h-4 text-slate-400 absolute left-3.5 top-1/2 -translate-y-1/2" />
          <input
            type="text"
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            placeholder="Buscar por código (ej: 1105) o nombre de cuenta..."
            className="w-full pl-10 pr-4 py-2 bg-slate-50 border border-slate-200 rounded-xl text-xs focus:outline-none focus:ring-2 focus:ring-blue-500 text-slate-800"
          />
        </div>

        <div className="flex items-center gap-2 w-full sm:w-auto">
          <Filter className="w-4 h-4 text-slate-400" />
          <select
            value={selectedClass}
            onChange={(e) => setSelectedClass(e.target.value)}
            className="bg-slate-50 border border-slate-200 rounded-xl text-xs py-2 px-3 focus:outline-none focus:ring-2 focus:ring-blue-500 text-slate-700"
          >
            <option value="ALL">Todas las Clases</option>
            <option value="1">1. Activo</option>
            <option value="2">2. Pasivo</option>
            <option value="3">3. Patrimonio</option>
            <option value="4">4. Ingresos</option>
            <option value="5">5. Gastos</option>
            <option value="6">6. Costos de Ventas</option>
            <option value="7">7. Costos de Producción</option>
          </select>
        </div>
      </div>

      {/* Tabla Jerárquica */}
      <div className="bg-white rounded-2xl border border-slate-200 shadow-sm overflow-hidden">
        <table className="w-full text-left text-xs">
          <thead className="bg-slate-50 text-slate-600 uppercase font-semibold border-b border-slate-100">
            <tr>
              <th className="py-3 px-4">Código</th>
              <th className="py-3 px-4">Nombre de la Cuenta</th>
              <th className="py-3 px-4 text-center">Nivel</th>
              <th className="py-3 px-4 text-center">Naturaleza</th>
              <th className="py-3 px-4 text-center">Movimiento</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-slate-100">
            {filtered.map((acc, idx) => (
              <tr key={idx} className="hover:bg-slate-50/60 transition-colors">
                <td className="py-2.5 px-4 font-mono font-semibold text-blue-600">
                  {acc.code}
                </td>
                <td className="py-2.5 px-4" style={{ paddingLeft: `${(acc.level || 1) * 16}px` }}>
                  <span className={(acc.level || 1) <= 2 ? 'font-bold text-slate-900' : 'text-slate-700'}>
                    {acc.name}
                  </span>
                </td>
                <td className="py-2.5 px-4 text-center">
                  <span className="px-2 py-0.5 rounded-full bg-slate-100 text-slate-600 font-semibold text-[10px]">
                    Nivel {acc.level || (acc.code.length <= 1 ? 1 : acc.code.length <= 2 ? 2 : acc.code.length <= 4 ? 3 : acc.code.length <= 6 ? 4 : 5)}
                  </span>
                </td>
                <td className="py-2.5 px-4 text-center">
                  <span className={`px-2 py-0.5 rounded-full text-[10px] font-semibold ${acc.nature === 'DEBIT' ? 'bg-blue-50 text-blue-700' : 'bg-amber-50 text-amber-700'}`}>
                    {acc.nature === 'DEBIT' ? 'Débito' : 'Crédito'}
                  </span>
                </td>
                <td className="py-2.5 px-4 text-center">
                  {acc.isMovement ? (
                    <span className="inline-flex items-center gap-1 text-emerald-600 font-semibold text-[11px]">
                      <CheckCircle2 className="w-3.5 h-3.5" />
                      <span>Sí (Auxiliar)</span>
                    </span>
                  ) : (
                    <span className="text-slate-400 text-[11px]">No (Mayor)</span>
                  )}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      {/* Modal Crear Cuenta */}
      {showModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-900/60 backdrop-blur-sm">
          <div className="bg-white w-full max-w-md rounded-2xl border border-slate-200 shadow-2xl p-6 space-y-4">
            <div className="flex items-center justify-between border-b border-slate-100 pb-3">
              <h3 className="text-base font-bold text-slate-900">Crear Nueva Cuenta PUC</h3>
              <button onClick={() => setShowModal(false)} className="text-slate-400 hover:text-slate-600">
                <X className="w-5 h-5" />
              </button>
            </div>

            <form onSubmit={handleCreateAccount} className="space-y-4">
              <div>
                <label className="block text-xs font-bold text-slate-700 mb-1">Código de Cuenta</label>
                <input
                  type="text"
                  required
                  placeholder="Ej. 11050502"
                  value={formData.code}
                  onChange={(e) => setFormData({ ...formData, code: e.target.value })}
                  className="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-xl text-xs font-mono font-bold text-slate-900"
                />
              </div>

              <div>
                <label className="block text-xs font-bold text-slate-700 mb-1">Nombre de la Cuenta</label>
                <input
                  type="text"
                  required
                  placeholder="Ej. Caja Menor Sucursal Norte"
                  value={formData.name}
                  onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                  className="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-xl text-xs text-slate-900"
                />
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-xs font-bold text-slate-700 mb-1">Naturaleza</label>
                  <select
                    value={formData.nature}
                    onChange={(e: any) => setFormData({ ...formData, nature: e.target.value })}
                    className="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-xl text-xs text-slate-900"
                  >
                    <option value="DEBIT">Débito</option>
                    <option value="CREDIT">Crédito</option>
                  </select>
                </div>

                <div className="flex items-end pb-2">
                  <label className="flex items-center gap-2 cursor-pointer text-xs font-bold text-slate-700">
                    <input
                      type="checkbox"
                      checked={formData.isMovement}
                      onChange={(e) => setFormData({ ...formData, isMovement: e.target.checked })}
                      className="rounded text-blue-600"
                    />
                    <span>Cuenta de Movimiento</span>
                  </label>
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
                  Guardar Cuenta
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
