'use client';

import React, { useState, useEffect } from 'react';
import {
  Users,
  Search,
  Plus,
  Edit2,
  Trash2,
  Building,
  UserCheck,
  Mail,
  Phone,
  MapPin,
  FileSpreadsheet,
  CheckCircle2,
  AlertCircle,
  X,
  RefreshCw,
  Calculator
} from 'lucide-react';

interface ThirdParty {
  id: string;
  documentType: string;
  documentNumber: string;
  verificationDigit?: string | null;
  businessName?: string | null;
  firstName?: string | null;
  lastName?: string | null;
  personType: string; // 'JURIDICA' | 'NATURAL'
  taxRegime: string;
  isClient: boolean;
  isSupplier: boolean;
  isEmployee: boolean;
  isOther: boolean;
  email?: string | null;
  phone?: string | null;
  address?: string | null;
  city?: string | null;
  department?: string | null;
  isActive: boolean;
}

export default function ThirdPartiesPage() {
  const [thirdParties, setThirdParties] = useState<ThirdParty[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState('');
  const [filterType, setFilterType] = useState('ALL');
  const [showModal, setShowModal] = useState(false);
  const [editingItem, setEditingItem] = useState<ThirdParty | null>(null);

  // Form State
  const [formData, setFormData] = useState({
    documentType: 'NIT',
    documentNumber: '',
    verificationDigit: '',
    businessName: '',
    firstName: '',
    lastName: '',
    personType: 'JURIDICA',
    taxRegime: 'RESPONSABLE_IVA',
    isClient: true,
    isSupplier: false,
    isEmployee: false,
    isOther: false,
    email: '',
    phone: '',
    address: '',
    city: 'Bogotá D.C.',
    department: 'Cundinamarca',
    isActive: true
  });

  const loadData = async () => {
    try {
      setLoading(true);
      const res = await fetch('/api/third-parties');
      if (res.ok) {
        const json = await res.json();
        setThirdParties(json.data || json || []);
      }
    } catch (e) {
      console.error('Error cargando terceros:', e);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadData();
  }, []);

  // DIAN Modulo 11 DV calculation
  const calculateDV = (nit: string): string => {
    const vpri = [3, 7, 13, 17, 19, 23, 29, 37, 41, 43, 47, 53, 59, 67, 71];
    const cleanNit = nit.replace(/\D/g, '');
    if (!cleanNit) return '';
    let total = 0;
    for (let i = 0; i < cleanNit.length; i++) {
      total += parseInt(cleanNit.charAt(cleanNit.length - 1 - i), 10) * vpri[i];
    }
    const residue = total % 11;
    if (residue === 0 || residue === 1) return residue.toString();
    return (11 - residue).toString();
  };

  const handleDocumentChange = (docNum: string) => {
    const dv = formData.documentType === 'NIT' ? calculateDV(docNum) : '';
    setFormData((prev) => ({
      ...prev,
      documentNumber: docNum,
      verificationDigit: dv
    }));
  };

  const handleOpenModal = (item?: ThirdParty) => {
    if (item) {
      setEditingItem(item);
      setFormData({
        documentType: item.documentType || 'NIT',
        documentNumber: item.documentNumber || '',
        verificationDigit: item.verificationDigit || '',
        businessName: item.businessName || '',
        firstName: item.firstName || '',
        lastName: item.lastName || '',
        personType: item.personType || 'JURIDICA',
        taxRegime: item.taxRegime || 'RESPONSABLE_IVA',
        isClient: item.isClient ?? true,
        isSupplier: item.isSupplier ?? false,
        isEmployee: item.isEmployee ?? false,
        isOther: item.isOther ?? false,
        email: item.email || '',
        phone: item.phone || '',
        address: item.address || '',
        city: item.city || 'Bogotá D.C.',
        department: item.department || 'Cundinamarca',
        isActive: item.isActive ?? true
      });
    } else {
      setEditingItem(null);
      setFormData({
        documentType: 'NIT',
        documentNumber: '',
        verificationDigit: '',
        businessName: '',
        firstName: '',
        lastName: '',
        personType: 'JURIDICA',
        taxRegime: 'RESPONSABLE_IVA',
        isClient: true,
        isSupplier: false,
        isEmployee: false,
        isOther: false,
        email: '',
        phone: '',
        address: '',
        city: 'Bogotá D.C.',
        department: 'Cundinamarca',
        isActive: true
      });
    }
    setShowModal(true);
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
      const url = editingItem ? `/api/third-parties/${editingItem.id}` : '/api/third-parties';
      const method = editingItem ? 'PUT' : 'POST';

      const res = await fetch(url, {
        method,
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(formData)
      });

      if (res.ok) {
        setShowModal(false);
        loadData();
      } else {
        const err = await res.json();
        alert(`Error al guardar tercero: ${err.message || err.error || 'Verifique los datos'}`);
      }
    } catch (e) {
      alert('Error de conexión con el servidor');
    }
  };

  const filteredThirdParties = thirdParties.filter((t) => {
    const fullName = `${t.businessName || ''} ${t.firstName || ''} ${t.lastName || ''}`.toLowerCase();
    const doc = (t.documentNumber || '').toLowerCase();
    const matchesSearch = fullName.includes(searchTerm.toLowerCase()) || doc.includes(searchTerm.toLowerCase());

    if (!matchesSearch) return false;
    if (filterType === 'CLIENT') return t.isClient;
    if (filterType === 'SUPPLIER') return t.isSupplier;
    if (filterType === 'EMPLOYEE') return t.isEmployee;
    return true;
  });

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 bg-white p-6 rounded-2xl border border-slate-200 shadow-sm">
        <div>
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-xl bg-blue-100 text-blue-600 flex items-center justify-center font-bold">
              <Users className="w-5 h-5" />
            </div>
            <div>
              <h1 className="text-xl font-bold text-slate-900">Directorio de Terceros y Clientes</h1>
              <p className="text-xs text-slate-500">Gestión tributaria DIAN, NIT con dígito de verificación y clasificación NIIF</p>
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
            onClick={() => handleOpenModal()}
            className="flex items-center gap-2 px-4 py-2.5 rounded-xl bg-blue-600 text-white text-xs font-semibold hover:bg-blue-700 shadow-sm shadow-blue-500/20 transition-all"
          >
            <Plus className="w-4 h-4" />
            <span>+ Nuevo Tercero</span>
          </button>
        </div>
      </div>

      {/* Stats Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-4 gap-4">
        <div className="bg-white p-4 rounded-xl border border-slate-200 shadow-sm flex items-center justify-between">
          <div>
            <p className="text-[11px] font-semibold text-slate-500 uppercase tracking-wider">Total Registrados</p>
            <p className="text-2xl font-bold text-slate-900 mt-1">{thirdParties.length}</p>
          </div>
          <div className="w-9 h-9 rounded-lg bg-blue-50 text-blue-600 flex items-center justify-center font-bold">
            <Users className="w-5 h-5" />
          </div>
        </div>

        <div className="bg-white p-4 rounded-xl border border-slate-200 shadow-sm flex items-center justify-between">
          <div>
            <p className="text-[11px] font-semibold text-slate-500 uppercase tracking-wider">Clientes</p>
            <p className="text-2xl font-bold text-emerald-600 mt-1">{thirdParties.filter(t => t.isClient).length}</p>
          </div>
          <div className="w-9 h-9 rounded-lg bg-emerald-50 text-emerald-600 flex items-center justify-center font-bold">
            <UserCheck className="w-5 h-5" />
          </div>
        </div>

        <div className="bg-white p-4 rounded-xl border border-slate-200 shadow-sm flex items-center justify-between">
          <div>
            <p className="text-[11px] font-semibold text-slate-500 uppercase tracking-wider">Proveedores</p>
            <p className="text-2xl font-bold text-indigo-600 mt-1">{thirdParties.filter(t => t.isSupplier).length}</p>
          </div>
          <div className="w-9 h-9 rounded-lg bg-indigo-50 text-indigo-600 flex items-center justify-center font-bold">
            <Building className="w-5 h-5" />
          </div>
        </div>

        <div className="bg-white p-4 rounded-xl border border-slate-200 shadow-sm flex items-center justify-between">
          <div>
            <p className="text-[11px] font-semibold text-slate-500 uppercase tracking-wider">Personas Jurídicas</p>
            <p className="text-2xl font-bold text-slate-700 mt-1">{thirdParties.filter(t => t.personType === 'JURIDICA').length}</p>
          </div>
          <div className="w-9 h-9 rounded-lg bg-slate-100 text-slate-600 flex items-center justify-center font-bold">
            <FileSpreadsheet className="w-5 h-5" />
          </div>
        </div>
      </div>

      {/* Filter and Search Bar */}
      <div className="bg-white p-4 rounded-2xl border border-slate-200 shadow-sm flex flex-col md:flex-row items-center justify-between gap-4">
        <div className="relative flex-1 w-full">
          <Search className="w-4 h-4 text-slate-400 absolute left-3.5 top-1/2 -translate-y-1/2" />
          <input
            type="text"
            placeholder="Buscar por NIT, cédula, razón social o nombre..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            className="w-full pl-10 pr-4 py-2.5 bg-slate-50 border border-slate-200 rounded-xl text-xs text-slate-900 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:bg-white transition-all"
          />
        </div>

        <div className="flex items-center gap-2 w-full md:w-auto">
          {['ALL', 'CLIENT', 'SUPPLIER', 'EMPLOYEE'].map((type) => {
            const labels: Record<string, string> = {
              ALL: 'Todos',
              CLIENT: 'Clientes',
              SUPPLIER: 'Proveedores',
              EMPLOYEE: 'Empleados'
            };
            return (
              <button
                key={type}
                onClick={() => setFilterType(type)}
                className={`px-3.5 py-2 rounded-xl text-xs font-semibold transition-all ${
                  filterType === type
                    ? 'bg-blue-600 text-white shadow-sm'
                    : 'bg-slate-50 text-slate-600 hover:bg-slate-100 border border-slate-200'
                }`}
              >
                {labels[type]}
              </button>
            );
          })}
        </div>
      </div>

      {/* Third Parties Table */}
      <div className="bg-white rounded-2xl border border-slate-200 shadow-sm overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse">
            <thead>
              <tr className="bg-slate-50 border-b border-slate-200 text-[11px] font-bold text-slate-500 uppercase tracking-wider">
                <th className="py-3 px-4">Documento / NIT</th>
                <th className="py-3 px-4">Razón Social / Nombre</th>
                <th className="py-3 px-4">Tipo / Régimen</th>
                <th className="py-3 px-4">Roles</th>
                <th className="py-3 px-4">Contacto</th>
                <th className="py-3 px-4">Ubicación</th>
                <th className="py-3 px-4 text-center">Estado</th>
                <th className="py-3 px-4 text-right">Acciones</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100 text-xs text-slate-700">
              {filteredThirdParties.length === 0 ? (
                <tr>
                  <td colSpan={8} className="py-12 text-center text-slate-400">
                    <Users className="w-10 h-10 mx-auto mb-2 text-slate-300" />
                    <p className="font-semibold">No se encontraron terceros registrados</p>
                    <p className="text-[11px] mt-0.5">Haz clic en "+ Nuevo Tercero" para registrar uno.</p>
                  </td>
                </tr>
              ) : (
                filteredThirdParties.map((item) => (
                  <tr key={item.id} className="hover:bg-slate-50/80 transition-colors">
                    <td className="py-3 px-4 font-mono font-bold text-slate-900">
                      {item.documentType} {item.documentNumber}
                      {item.verificationDigit ? `-${item.verificationDigit}` : ''}
                    </td>
                    <td className="py-3 px-4 font-semibold text-slate-800">
                      {item.personType === 'JURIDICA' ? item.businessName : `${item.firstName || ''} ${item.lastName || ''}`}
                    </td>
                    <td className="py-3 px-4">
                      <span className="inline-block px-2 py-0.5 rounded text-[10px] font-semibold bg-slate-100 text-slate-700 mr-1">
                        {item.personType}
                      </span>
                      <span className="inline-block text-[10px] text-slate-500">
                        {item.taxRegime}
                      </span>
                    </td>
                    <td className="py-3 px-4">
                      <div className="flex flex-wrap gap-1">
                        {item.isClient && (
                          <span className="px-1.5 py-0.5 rounded text-[10px] font-bold bg-emerald-50 text-emerald-700 border border-emerald-200">
                            Cliente
                          </span>
                        )}
                        {item.isSupplier && (
                          <span className="px-1.5 py-0.5 rounded text-[10px] font-bold bg-indigo-50 text-indigo-700 border border-indigo-200">
                            Proveedor
                          </span>
                        )}
                        {item.isEmployee && (
                          <span className="px-1.5 py-0.5 rounded text-[10px] font-bold bg-amber-50 text-amber-700 border border-amber-200">
                            Empleado
                          </span>
                        )}
                      </div>
                    </td>
                    <td className="py-3 px-4 text-[11px] text-slate-500">
                      {item.email && <div className="flex items-center gap-1"><Mail className="w-3 h-3 text-slate-400" /> {item.email}</div>}
                      {item.phone && <div className="flex items-center gap-1 mt-0.5"><Phone className="w-3 h-3 text-slate-400" /> {item.phone}</div>}
                    </td>
                    <td className="py-3 px-4 text-[11px] text-slate-500">
                      {item.city && <div className="flex items-center gap-1"><MapPin className="w-3 h-3 text-slate-400" /> {item.city}</div>}
                    </td>
                    <td className="py-3 px-4 text-center">
                      <span className={`inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-[10px] font-bold ${
                        item.isActive ? 'bg-emerald-50 text-emerald-700' : 'bg-rose-50 text-rose-700'
                      }`}>
                        {item.isActive ? 'Activo' : 'Inactivo'}
                      </span>
                    </td>
                    <td className="py-3 px-4 text-right">
                      <button
                        onClick={() => handleOpenModal(item)}
                        className="p-1.5 rounded-lg text-slate-400 hover:text-blue-600 hover:bg-blue-50 transition-colors mr-1"
                        title="Editar"
                      >
                        <Edit2 className="w-3.5 h-3.5" />
                      </button>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>

      {/* Modal Form */}
      {showModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-900/60 backdrop-blur-sm animate-fadeIn">
          <div className="bg-white w-full max-w-2xl rounded-2xl border border-slate-200 shadow-2xl overflow-hidden flex flex-col max-h-[90vh]">
            <div className="flex items-center justify-between px-6 py-4 border-b border-slate-200 bg-slate-50">
              <div className="flex items-center gap-2.5">
                <div className="w-8 h-8 rounded-lg bg-blue-100 text-blue-600 flex items-center justify-center font-bold">
                  <Users className="w-4 h-4" />
                </div>
                <h3 className="text-base font-bold text-slate-900">
                  {editingItem ? 'Editar Tercero' : 'Registrar Nuevo Tercero'}
                </h3>
              </div>
              <button onClick={() => setShowModal(false)} className="text-slate-400 hover:text-slate-600">
                <X className="w-5 h-5" />
              </button>
            </div>

            <form onSubmit={handleSubmit} className="flex-1 overflow-y-auto p-6 space-y-4">
              {/* Persona & Documento */}
              <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
                <div>
                  <label className="block text-xs font-bold text-slate-700 mb-1">Tipo de Persona</label>
                  <select
                    value={formData.personType}
                    onChange={(e) => setFormData({ ...formData, personType: e.target.value })}
                    className="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-xl text-xs text-slate-900 focus:bg-white focus:ring-2 focus:ring-blue-500"
                  >
                    <option value="JURIDICA">Jurídica</option>
                    <option value="NATURAL">Natural</option>
                  </select>
                </div>

                <div>
                  <label className="block text-xs font-bold text-slate-700 mb-1">Tipo de Documento</label>
                  <select
                    value={formData.documentType}
                    onChange={(e) => {
                      const docType = e.target.value;
                      const dv = docType === 'NIT' ? calculateDV(formData.documentNumber) : '';
                      setFormData({ ...formData, documentType: docType, verificationDigit: dv });
                    }}
                    className="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-xl text-xs text-slate-900 focus:bg-white focus:ring-2 focus:ring-blue-500"
                  >
                    <option value="NIT">NIT - Tributario</option>
                    <option value="CC">Cédula de Ciudadanía</option>
                    <option value="CE">Cédula de Extranjería</option>
                    <option value="PASAPORTE">Pasaporte</option>
                    <option value="TI">Tarjeta de Identidad</option>
                  </select>
                </div>

                <div>
                  <label className="block text-xs font-bold text-slate-700 mb-1">Número de Documento</label>
                  <div className="flex gap-2">
                    <input
                      type="text"
                      required
                      value={formData.documentNumber}
                      onChange={(e) => handleDocumentChange(e.target.value)}
                      placeholder="900123456"
                      className="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-xl text-xs font-mono text-slate-900 focus:bg-white focus:ring-2 focus:ring-blue-500"
                    />
                    {formData.documentType === 'NIT' && (
                      <div className="w-12 flex items-center justify-center bg-blue-50 border border-blue-200 rounded-xl text-xs font-mono font-bold text-blue-700">
                        {formData.verificationDigit || '-'}
                      </div>
                    )}
                  </div>
                </div>
              </div>

              {/* Razón Social / Nombres */}
              {formData.personType === 'JURIDICA' ? (
                <div>
                  <label className="block text-xs font-bold text-slate-700 mb-1">Razón Social</label>
                  <input
                    type="text"
                    required
                    value={formData.businessName}
                    onChange={(e) => setFormData({ ...formData, businessName: e.target.value })}
                    placeholder="Ej. Comercializadora Andina S.A.S."
                    className="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-xl text-xs text-slate-900 focus:bg-white focus:ring-2 focus:ring-blue-500"
                  />
                </div>
              ) : (
                <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                  <div>
                    <label className="block text-xs font-bold text-slate-700 mb-1">Nombres</label>
                    <input
                      type="text"
                      required
                      value={formData.firstName}
                      onChange={(e) => setFormData({ ...formData, firstName: e.target.value })}
                      placeholder="Ej. Juan Carlos"
                      className="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-xl text-xs text-slate-900 focus:bg-white focus:ring-2 focus:ring-blue-500"
                    />
                  </div>
                  <div>
                    <label className="block text-xs font-bold text-slate-700 mb-1">Apellidos</label>
                    <input
                      type="text"
                      required
                      value={formData.lastName}
                      onChange={(e) => setFormData({ ...formData, lastName: e.target.value })}
                      placeholder="Ej. Pérez Gómez"
                      className="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-xl text-xs text-slate-900 focus:bg-white focus:ring-2 focus:ring-blue-500"
                    />
                  </div>
                </div>
              )}

              {/* Régimen Tributario */}
              <div>
                <label className="block text-xs font-bold text-slate-700 mb-1">Régimen Tributario</label>
                <select
                  value={formData.taxRegime}
                  onChange={(e) => setFormData({ ...formData, taxRegime: e.target.value })}
                  className="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-xl text-xs text-slate-900 focus:bg-white focus:ring-2 focus:ring-blue-500"
                >
                  <option value="RESPONSABLE_IVA">Responsable de IVA (Común)</option>
                  <option value="NO_RESPONSABLE_IVA">No Responsable de IVA (Simplificado)</option>
                  <option value="GRAN_CONTRIBUYENTE">Gran Contribuyente</option>
                  <option value="AUTORRETENEDOR">Autorretenedor</option>
                  <option value="SIMPLE">Régimen Simple de Tributación (RST)</option>
                </select>
              </div>

              {/* Clasificación de Roles */}
              <div>
                <label className="block text-xs font-bold text-slate-700 mb-2">Clasificación Operativa</label>
                <div className="grid grid-cols-2 sm:grid-cols-4 gap-3">
                  <label className="flex items-center gap-2 p-2.5 bg-slate-50 rounded-xl border border-slate-200 text-xs font-medium cursor-pointer hover:bg-slate-100">
                    <input
                      type="checkbox"
                      checked={formData.isClient}
                      onChange={(e) => setFormData({ ...formData, isClient: e.target.checked })}
                      className="rounded text-blue-600 focus:ring-blue-500"
                    />
                    <span>Cliente</span>
                  </label>
                  <label className="flex items-center gap-2 p-2.5 bg-slate-50 rounded-xl border border-slate-200 text-xs font-medium cursor-pointer hover:bg-slate-100">
                    <input
                      type="checkbox"
                      checked={formData.isSupplier}
                      onChange={(e) => setFormData({ ...formData, isSupplier: e.target.checked })}
                      className="rounded text-blue-600 focus:ring-blue-500"
                    />
                    <span>Proveedor</span>
                  </label>
                  <label className="flex items-center gap-2 p-2.5 bg-slate-50 rounded-xl border border-slate-200 text-xs font-medium cursor-pointer hover:bg-slate-100">
                    <input
                      type="checkbox"
                      checked={formData.isEmployee}
                      onChange={(e) => setFormData({ ...formData, isEmployee: e.target.checked })}
                      className="rounded text-blue-600 focus:ring-blue-500"
                    />
                    <span>Empleado</span>
                  </label>
                  <label className="flex items-center gap-2 p-2.5 bg-slate-50 rounded-xl border border-slate-200 text-xs font-medium cursor-pointer hover:bg-slate-100">
                    <input
                      type="checkbox"
                      checked={formData.isOther}
                      onChange={(e) => setFormData({ ...formData, isOther: e.target.checked })}
                      className="rounded text-blue-600 focus:ring-blue-500"
                    />
                    <span>Otro</span>
                  </label>
                </div>
              </div>

              {/* Contacto & Ubicación */}
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                <div>
                  <label className="block text-xs font-bold text-slate-700 mb-1">Correo Electrónico</label>
                  <input
                    type="email"
                    value={formData.email}
                    onChange={(e) => setFormData({ ...formData, email: e.target.value })}
                    placeholder="contacto@empresa.com"
                    className="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-xl text-xs text-slate-900 focus:bg-white focus:ring-2 focus:ring-blue-500"
                  />
                </div>
                <div>
                  <label className="block text-xs font-bold text-slate-700 mb-1">Teléfono / Celular</label>
                  <input
                    type="text"
                    value={formData.phone}
                    onChange={(e) => setFormData({ ...formData, phone: e.target.value })}
                    placeholder="601 123 4567"
                    className="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-xl text-xs text-slate-900 focus:bg-white focus:ring-2 focus:ring-blue-500"
                  />
                </div>
              </div>

              <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
                <div>
                  <label className="block text-xs font-bold text-slate-700 mb-1">Dirección</label>
                  <input
                    type="text"
                    value={formData.address}
                    onChange={(e) => setFormData({ ...formData, address: e.target.value })}
                    placeholder="Calle 100 # 15-20"
                    className="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-xl text-xs text-slate-900 focus:bg-white focus:ring-2 focus:ring-blue-500"
                  />
                </div>
                <div>
                  <label className="block text-xs font-bold text-slate-700 mb-1">Ciudad / Municipio</label>
                  <input
                    type="text"
                    value={formData.city}
                    onChange={(e) => setFormData({ ...formData, city: e.target.value })}
                    placeholder="Bogotá D.C."
                    className="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-xl text-xs text-slate-900 focus:bg-white focus:ring-2 focus:ring-blue-500"
                  />
                </div>
                <div>
                  <label className="block text-xs font-bold text-slate-700 mb-1">Departamento</label>
                  <input
                    type="text"
                    value={formData.department}
                    onChange={(e) => setFormData({ ...formData, department: e.target.value })}
                    placeholder="Cundinamarca"
                    className="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-xl text-xs text-slate-900 focus:bg-white focus:ring-2 focus:ring-blue-500"
                  />
                </div>
              </div>
            </form>

            <div className="px-6 py-4 bg-slate-50 border-t border-slate-200 flex items-center justify-end gap-3">
              <button
                type="button"
                onClick={() => setShowModal(false)}
                className="px-4 py-2 rounded-xl text-xs font-semibold text-slate-600 hover:bg-slate-200/60 transition-colors"
              >
                Cancelar
              </button>
              <button
                onClick={handleSubmit}
                className="px-5 py-2 rounded-xl text-xs font-semibold bg-blue-600 text-white hover:bg-blue-700 shadow-sm shadow-blue-500/20 transition-all"
              >
                {editingItem ? 'Guardar Cambios' : 'Crear Tercero'}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
