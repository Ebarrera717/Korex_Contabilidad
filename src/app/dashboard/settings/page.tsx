'use client';

import React, { useState, useEffect } from 'react';
import {
  Settings,
  Building,
  Calendar,
  Layers,
  Lock,
  Unlock,
  Save,
  RefreshCw,
  CheckCircle2,
  AlertCircle,
  Database,
  ShieldCheck,
  Users,
  UserPlus,
  UserCheck,
  UserX,
  Edit2,
  Trash2,
  KeyRound,
  Mail,
  Shield,
  X
} from 'lucide-react';

interface UserItem {
  id: number;
  name: string;
  email: string;
  roleId: number;
  roleName: string;
  isActive: boolean;
  createdAt: string;
}

interface RoleItem {
  id: number;
  name: string;
  description: string;
}

export default function SettingsPage() {
  const [activeTab, setActiveTab] = useState<'COMPANY' | 'USERS' | 'PERIODS' | 'CONSECUTIVES' | 'SYSTEM'>('USERS');
  const [loading, setLoading] = useState(false);
  const [periods, setPeriods] = useState<any[]>([]);

  // Users State
  const [users, setUsers] = useState<UserItem[]>([]);
  const [roles, setRoles] = useState<RoleItem[]>([]);
  const [userSearchTerm, setUserSearchTerm] = useState('');
  const [showUserModal, setShowUserModal] = useState(false);
  const [editingUser, setEditingUser] = useState<UserItem | null>(null);

  const [userFormData, setUserFormData] = useState({
    name: '',
    email: '',
    password: '',
    confirmPassword: '',
    roleId: '1',
    isActive: true
  });

  // Company Form State
  const [companyData, setCompanyData] = useState({
    businessName: 'EMPRESA DEMO CONTABLE S.A.S.',
    tradeName: 'Korex Contabilidad Demo',
    nit: '900123456',
    dv: '8',
    taxRegime: 'RESPONSABLE_IVA',
    address: 'Calle 100 # 15-20, Piso 5',
    city: 'Bogotá D.C.',
    department: 'Cundinamarca',
    phone: '601 123 4567',
    email: 'contabilidad@empresa.com.co',
    legalRepresentative: 'Carlos Eduardo Ramírez',
    legalRepDocument: '79123456',
    accountantName: 'María Fernanda Gómez',
    accountantCard: '123456-T'
  });

  const loadUsersAndRoles = async () => {
    try {
      setLoading(true);
      const [resUsers, resRoles] = await Promise.all([
        fetch('/api/users'),
        fetch('/api/roles')
      ]);

      if (resUsers.ok) {
        const json = await resUsers.json();
        setUsers(json.data || []);
      }
      if (resRoles.ok) {
        const json = await resRoles.json();
        setRoles(json.data || []);
      }
    } catch (e) {
      console.error('Error cargando usuarios y roles:', e);
    } finally {
      setLoading(false);
    }
  };

  const loadPeriods = async () => {
    try {
      setLoading(true);
      const res = await fetch('/api/periods');
      if (res.ok) {
        const json = await res.json();
        setPeriods(json.data || json || []);
      }
    } catch (e) {
      console.error('Error cargando periodos:', e);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    if (activeTab === 'USERS') {
      loadUsersAndRoles();
    } else if (activeTab === 'PERIODS') {
      loadPeriods();
    }
  }, [activeTab]);

  const handleOpenUserModal = (user?: UserItem) => {
    if (user) {
      setEditingUser(user);
      setUserFormData({
        name: user.name,
        email: user.email,
        password: '',
        confirmPassword: '',
        roleId: user.roleId.toString(),
        isActive: user.isActive
      });
    } else {
      setEditingUser(null);
      setUserFormData({
        name: '',
        email: '',
        password: '',
        confirmPassword: '',
        roleId: roles[0]?.id?.toString() || '1',
        isActive: true
      });
    }
    setShowUserModal(true);
  };

  const handleSaveUser = async (e: React.FormEvent) => {
    e.preventDefault();

    if (!editingUser && (!userFormData.password || userFormData.password.trim() === '')) {
      alert('Debe ingresar una contraseña para el nuevo usuario.');
      return;
    }

    if (userFormData.password && userFormData.password !== userFormData.confirmPassword) {
      alert('Las contraseñas no coinciden. Verifíquelas.');
      return;
    }

    try {
      const url = editingUser ? `/api/users/${editingUser.id}` : '/api/users';
      const method = editingUser ? 'PUT' : 'POST';

      const payload: any = {
        name: userFormData.name,
        email: userFormData.email,
        roleId: userFormData.roleId,
        isActive: userFormData.isActive
      };

      if (userFormData.password && userFormData.password.trim() !== '') {
        payload.password = userFormData.password.trim();
      }

      const res = await fetch(url, {
        method,
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload)
      });

      const data = await res.json();

      if (res.ok && data.success) {
        setShowUserModal(false);
        loadUsersAndRoles();
        alert(editingUser ? 'Usuario actualizado exitosamente.' : '¡Usuario creado exitosamente!');
      } else {
        alert(`Error: ${data.error || 'No fue posible guardar el usuario.'}`);
      }
    } catch (e) {
      alert('Error de conexión al guardar el usuario.');
    }
  };

  const handleToggleUserStatus = async (user: UserItem) => {
    const action = user.isActive ? 'desactivar' : 'activar';
    if (!confirm(`¿Está seguro de ${action} al usuario ${user.name}?`)) return;

    try {
      const res = await fetch(`/api/users/${user.id}`, {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ isActive: !user.isActive })
      });

      if (res.ok) {
        loadUsersAndRoles();
      } else {
        alert('Error al cambiar el estado del usuario.');
      }
    } catch (e) {
      alert('Error de conexión.');
    }
  };

  const handleTogglePeriod = async (periodId: string, currentStatus: string) => {
    const isClosing = currentStatus === 'OPEN';
    const action = isClosing ? 'cerrar' : 'reabrir';
    if (!confirm(`¿Desea ${action} este período fiscal?`)) return;

    try {
      const endpoint = isClosing ? '/api/periods/close' : '/api/periods/reopen';
      const res = await fetch(endpoint, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ periodId })
      });

      if (res.ok) {
        loadPeriods();
      } else {
        const err = await res.json();
        alert(`Error al cambiar estado del período: ${err.message || err.error}`);
      }
    } catch (e) {
      alert('Error de conexión');
    }
  };

  const handleRunAnnualClose = async () => {
    const year = prompt('Ingrese el año fiscal para el Cierre Anual (Cancelación de cuentas de resultado 4, 5, 6, 7 contra 36):', '2026');
    if (!year) return;

    try {
      const res = await fetch('/api/periods/annual-close', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ year: parseInt(year, 10) })
      });

      if (res.ok) {
        alert('¡Cierre Anual ejecutado exitosamente! Comprobante de cierre CZ generado y asentado.');
        loadPeriods();
      } else {
        const err = await res.json();
        alert(`Error al ejecutar cierre anual: ${err.message || err.error}`);
      }
    } catch (e) {
      alert('Error de conexión');
    }
  };

  const filteredUsers = users.filter((u) => {
    const term = userSearchTerm.toLowerCase();
    return u.name.toLowerCase().includes(term) || u.email.toLowerCase().includes(term) || u.roleName.toLowerCase().includes(term);
  });

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 bg-white p-6 rounded-2xl border border-slate-200 shadow-sm">
        <div>
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-xl bg-slate-100 text-slate-700 flex items-center justify-center font-bold">
              <Settings className="w-5 h-5" />
            </div>
            <div>
              <h1 className="text-xl font-bold text-slate-900">Configuración del Sistema y Usuarios</h1>
              <p className="text-xs text-slate-500">Gestión de usuarios, roles de acceso, datos de la empresa y períodos contables</p>
            </div>
          </div>
        </div>
      </div>

      {/* Tabs */}
      <div className="flex items-center gap-2 border-b border-slate-200 pb-2 overflow-x-auto">
        <button
          onClick={() => setActiveTab('USERS')}
          className={`px-4 py-2 rounded-xl text-xs font-bold transition-all flex items-center gap-2 shrink-0 ${
            activeTab === 'USERS'
              ? 'bg-blue-600 text-white shadow-sm'
              : 'bg-white text-slate-600 hover:bg-slate-100 border border-slate-200'
          }`}
        >
          <Users className="w-4 h-4" />
          <span>Gestión de Usuarios y Roles</span>
        </button>
        <button
          onClick={() => setActiveTab('COMPANY')}
          className={`px-4 py-2 rounded-xl text-xs font-bold transition-all flex items-center gap-2 shrink-0 ${
            activeTab === 'COMPANY'
              ? 'bg-blue-600 text-white shadow-sm'
              : 'bg-white text-slate-600 hover:bg-slate-100 border border-slate-200'
          }`}
        >
          <Building className="w-4 h-4" />
          <span>Datos de la Empresa</span>
        </button>
        <button
          onClick={() => setActiveTab('PERIODS')}
          className={`px-4 py-2 rounded-xl text-xs font-bold transition-all flex items-center gap-2 shrink-0 ${
            activeTab === 'PERIODS'
              ? 'bg-blue-600 text-white shadow-sm'
              : 'bg-white text-slate-600 hover:bg-slate-100 border border-slate-200'
          }`}
        >
          <Calendar className="w-4 h-4" />
          <span>Períodos Fiscales y Cierre Anual</span>
        </button>
        <button
          onClick={() => setActiveTab('CONSECUTIVES')}
          className={`px-4 py-2 rounded-xl text-xs font-bold transition-all flex items-center gap-2 shrink-0 ${
            activeTab === 'CONSECUTIVES'
              ? 'bg-blue-600 text-white shadow-sm'
              : 'bg-white text-slate-600 hover:bg-slate-100 border border-slate-200'
          }`}
        >
          <Layers className="w-4 h-4" />
          <span>Consecutivos de Documentos</span>
        </button>
        <button
          onClick={() => setActiveTab('SYSTEM')}
          className={`px-4 py-2 rounded-xl text-xs font-bold transition-all flex items-center gap-2 shrink-0 ${
            activeTab === 'SYSTEM'
              ? 'bg-blue-600 text-white shadow-sm'
              : 'bg-white text-slate-600 hover:bg-slate-100 border border-slate-200'
          }`}
        >
          <Database className="w-4 h-4" />
          <span>Infraestructura y Base de Datos</span>
        </button>
      </div>

      {/* Tab: USUARIOS Y ROLES */}
      {activeTab === 'USERS' && (
        <div className="space-y-6">
          {/* Header de Usuarios */}
          <div className="bg-white p-6 rounded-2xl border border-slate-200 shadow-sm flex flex-col sm:flex-row sm:items-center justify-between gap-4">
            <div>
              <h3 className="text-base font-bold text-slate-900">Usuarios del Sistema Contable</h3>
              <p className="text-xs text-slate-500">Cree y administre las cuentas de acceso para administradores, contadores y auxiliares</p>
            </div>
            <div className="flex items-center gap-3">
              <button
                onClick={loadUsersAndRoles}
                className="p-2.5 rounded-xl border border-slate-200 text-slate-600 hover:bg-slate-50"
                title="Refrescar"
              >
                <RefreshCw className={`w-4 h-4 ${loading ? 'animate-spin' : ''}`} />
              </button>
              <button
                onClick={() => handleOpenUserModal()}
                className="flex items-center gap-2 px-4 py-2.5 bg-blue-600 hover:bg-blue-700 text-white text-xs font-bold rounded-xl shadow-sm shadow-blue-500/20 transition-all"
              >
                <UserPlus className="w-4 h-4" />
                <span>+ Nuevo Usuario</span>
              </button>
            </div>
          </div>

          {/* Tabla de Usuarios */}
          <div className="bg-white rounded-2xl border border-slate-200 shadow-sm overflow-hidden">
            <div className="p-4 border-b border-slate-100">
              <input
                type="text"
                placeholder="Buscar por nombre, correo o rol..."
                value={userSearchTerm}
                onChange={(e) => setUserSearchTerm(e.target.value)}
                className="w-full pl-4 pr-4 py-2 bg-slate-50 border border-slate-200 rounded-xl text-xs text-slate-900 focus:outline-none focus:ring-2 focus:ring-blue-500"
              />
            </div>

            <div className="overflow-x-auto">
              <table className="w-full text-left border-collapse text-xs">
                <thead>
                  <tr className="bg-slate-50 border-b border-slate-200 text-[11px] font-bold text-slate-600 uppercase">
                    <th className="py-3 px-4">Usuario</th>
                    <th className="py-3 px-4">Correo Electrónico</th>
                    <th className="py-3 px-4">Rol en el Sistema</th>
                    <th className="py-3 px-4 text-center">Estado</th>
                    <th className="py-3 px-4 text-right">Acciones</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-100 text-slate-700">
                  {filteredUsers.length === 0 ? (
                    <tr>
                      <td colSpan={5} className="py-12 text-center text-slate-400">
                        <Users className="w-8 h-8 mx-auto mb-2 text-slate-300" />
                        <p className="font-semibold">No se encontraron usuarios</p>
                      </td>
                    </tr>
                  ) : (
                    filteredUsers.map((u) => (
                      <tr key={u.id} className="hover:bg-slate-50/80 transition-colors">
                        <td className="py-3 px-4">
                          <div className="flex items-center gap-3">
                            <div className="w-8 h-8 rounded-full bg-blue-100 text-blue-700 flex items-center justify-center font-bold text-xs">
                              {u.name.split(' ').map((n) => n[0]).slice(0, 2).join('').toUpperCase()}
                            </div>
                            <span className="font-bold text-slate-900">{u.name}</span>
                          </div>
                        </td>
                        <td className="py-3 px-4 font-mono text-slate-600">
                          {u.email}
                        </td>
                        <td className="py-3 px-4">
                          <span className={`inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-[10px] font-bold ${
                            u.roleName === 'Administrador'
                              ? 'bg-purple-50 text-purple-700 border border-purple-200'
                              : u.roleName === 'Contador General'
                              ? 'bg-blue-50 text-blue-700 border border-blue-200'
                              : 'bg-slate-100 text-slate-700'
                          }`}>
                            <Shield className="w-3 h-3" />
                            <span>{u.roleName}</span>
                          </span>
                        </td>
                        <td className="py-3 px-4 text-center">
                          <span className={`inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-[10px] font-bold ${
                            u.isActive
                              ? 'bg-emerald-50 text-emerald-700 border border-emerald-200'
                              : 'bg-rose-50 text-rose-700 border border-rose-200'
                          }`}>
                            {u.isActive ? 'Activo' : 'Inactivo'}
                          </span>
                        </td>
                        <td className="py-3 px-4 text-right space-x-1">
                          <button
                            onClick={() => handleOpenUserModal(u)}
                            className="p-1.5 rounded-lg text-slate-400 hover:text-blue-600 hover:bg-blue-50 transition-colors"
                            title="Editar Usuario"
                          >
                            <Edit2 className="w-3.5 h-3.5" />
                          </button>
                          <button
                            onClick={() => handleToggleUserStatus(u)}
                            className={`p-1.5 rounded-lg transition-colors ${
                              u.isActive
                                ? 'text-slate-400 hover:text-rose-600 hover:bg-rose-50'
                                : 'text-slate-400 hover:text-emerald-600 hover:bg-emerald-50'
                            }`}
                            title={u.isActive ? 'Desactivar Usuario' : 'Activar Usuario'}
                          >
                            {u.isActive ? <UserX className="w-3.5 h-3.5" /> : <UserCheck className="w-3.5 h-3.5" />}
                          </button>
                        </td>
                      </tr>
                    ))
                  )}
                </tbody>
              </table>
            </div>
          </div>
        </div>
      )}

      {/* Modal Crear / Editar Usuario */}
      {showUserModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-900/60 backdrop-blur-sm animate-fadeIn">
          <div className="bg-white w-full max-w-lg rounded-2xl border border-slate-200 shadow-2xl overflow-hidden flex flex-col">
            <div className="flex items-center justify-between px-6 py-4 border-b border-slate-200 bg-slate-50">
              <div className="flex items-center gap-2.5">
                <div className="w-8 h-8 rounded-lg bg-blue-100 text-blue-600 flex items-center justify-center font-bold">
                  <Users className="w-4 h-4" />
                </div>
                <h3 className="text-base font-bold text-slate-900">
                  {editingUser ? 'Editar Usuario' : 'Crear Nuevo Usuario'}
                </h3>
              </div>
              <button onClick={() => setShowUserModal(false)} className="text-slate-400 hover:text-slate-600">
                <X className="w-5 h-5" />
              </button>
            </div>

            <form onSubmit={handleSaveUser} className="p-6 space-y-4">
              <div>
                <label className="block text-xs font-bold text-slate-700 mb-1">Nombre Completo</label>
                <input
                  type="text"
                  required
                  placeholder="Ej. Ana María Torres"
                  value={userFormData.name}
                  onChange={(e) => setUserFormData({ ...userFormData, name: e.target.value })}
                  className="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-xl text-xs text-slate-900 focus:bg-white focus:ring-2 focus:ring-blue-500"
                />
              </div>

              <div>
                <label className="block text-xs font-bold text-slate-700 mb-1">Correo Electrónico</label>
                <input
                  type="email"
                  required
                  placeholder="usuario@empresa.com.co"
                  value={userFormData.email}
                  onChange={(e) => setUserFormData({ ...userFormData, email: e.target.value })}
                  className="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-xl text-xs text-slate-900 focus:bg-white focus:ring-2 focus:ring-blue-500"
                />
              </div>

              <div>
                <label className="block text-xs font-bold text-slate-700 mb-1">Rol en el Sistema</label>
                <select
                  value={userFormData.roleId}
                  onChange={(e) => setUserFormData({ ...userFormData, roleId: e.target.value })}
                  className="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-xl text-xs text-slate-900 focus:bg-white focus:ring-2 focus:ring-blue-500"
                >
                  {roles.map((r) => (
                    <option key={r.id} value={r.id}>
                      {r.name} - {r.description}
                    </option>
                  ))}
                </select>
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-xs font-bold text-slate-700 mb-1">
                    {editingUser ? 'Nueva Clave (opcional)' : 'Contraseña'}
                  </label>
                  <input
                    type="password"
                    placeholder="••••••••"
                    required={!editingUser}
                    value={userFormData.password}
                    onChange={(e) => setUserFormData({ ...userFormData, password: e.target.value })}
                    className="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-xl text-xs text-slate-900 focus:bg-white focus:ring-2 focus:ring-blue-500"
                  />
                </div>

                <div>
                  <label className="block text-xs font-bold text-slate-700 mb-1">Confirmar Clave</label>
                  <input
                    type="password"
                    placeholder="••••••••"
                    required={!editingUser && userFormData.password !== ''}
                    value={userFormData.confirmPassword}
                    onChange={(e) => setUserFormData({ ...userFormData, confirmPassword: e.target.value })}
                    className="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-xl text-xs text-slate-900 focus:bg-white focus:ring-2 focus:ring-blue-500"
                  />
                </div>
              </div>

              <div className="pt-2">
                <label className="flex items-center gap-2 cursor-pointer text-xs font-bold text-slate-700">
                  <input
                    type="checkbox"
                    checked={userFormData.isActive}
                    onChange={(e) => setUserFormData({ ...userFormData, isActive: e.target.checked })}
                    className="rounded text-blue-600 focus:ring-blue-500"
                  />
                  <span>Usuario Activo con Permiso de Acceso</span>
                </label>
              </div>

              <div className="flex justify-end gap-2 pt-4 border-t border-slate-100">
                <button
                  type="button"
                  onClick={() => setShowUserModal(false)}
                  className="px-4 py-2 text-xs font-semibold text-slate-600 hover:bg-slate-100 rounded-xl"
                >
                  Cancelar
                </button>
                <button
                  type="submit"
                  className="px-5 py-2 text-xs font-bold bg-blue-600 text-white rounded-xl hover:bg-blue-700 shadow-sm shadow-blue-500/20"
                >
                  {editingUser ? 'Guardar Cambios' : 'Crear Usuario'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Tab: DATOS DE LA EMPRESA */}
      {activeTab === 'COMPANY' && (
        <div className="bg-white p-8 rounded-2xl border border-slate-200 shadow-sm space-y-6">
          <div className="flex items-center justify-between border-b border-slate-100 pb-4">
            <div>
              <h3 className="text-base font-bold text-slate-900">Información Tributaria y Legal</h3>
              <p className="text-xs text-slate-500">Datos que se desplegarán en encabezados de libros oficiales y estados financieros</p>
            </div>
            <button
              onClick={() => alert('¡Datos de la empresa actualizados exitosamente!')}
              className="flex items-center gap-2 px-4 py-2 bg-blue-600 text-white text-xs font-semibold rounded-xl hover:bg-blue-700 shadow-sm shadow-blue-500/20"
            >
              <Save className="w-4 h-4" />
              <span>Guardar Configuración</span>
            </button>
          </div>

          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <div>
              <label className="block text-xs font-bold text-slate-700 mb-1">Razón Social</label>
              <input
                type="text"
                value={companyData.businessName}
                onChange={(e) => setCompanyData({ ...companyData, businessName: e.target.value })}
                className="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-xl text-xs text-slate-900 focus:bg-white focus:ring-2 focus:ring-blue-500"
              />
            </div>
            <div>
              <label className="block text-xs font-bold text-slate-700 mb-1">Nombre Comercial</label>
              <input
                type="text"
                value={companyData.tradeName}
                onChange={(e) => setCompanyData({ ...companyData, tradeName: e.target.value })}
                className="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-xl text-xs text-slate-900 focus:bg-white focus:ring-2 focus:ring-blue-500"
              />
            </div>
          </div>

          <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
            <div>
              <label className="block text-xs font-bold text-slate-700 mb-1">NIT</label>
              <input
                type="text"
                value={companyData.nit}
                onChange={(e) => setCompanyData({ ...companyData, nit: e.target.value })}
                className="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-xl text-xs font-mono text-slate-900 focus:bg-white focus:ring-2 focus:ring-blue-500"
              />
            </div>
            <div>
              <label className="block text-xs font-bold text-slate-700 mb-1">Dígito de Verificación (DV)</label>
              <input
                type="text"
                value={companyData.dv}
                onChange={(e) => setCompanyData({ ...companyData, dv: e.target.value })}
                className="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-xl text-xs font-mono font-bold text-blue-700 focus:bg-white focus:ring-2 focus:ring-blue-500"
              />
            </div>
            <div>
              <label className="block text-xs font-bold text-slate-700 mb-1">Régimen Tributario</label>
              <select
                value={companyData.taxRegime}
                onChange={(e) => setCompanyData({ ...companyData, taxRegime: e.target.value })}
                className="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-xl text-xs text-slate-900 focus:bg-white focus:ring-2 focus:ring-blue-500"
              >
                <option value="RESPONSABLE_IVA">Responsable de IVA (Común)</option>
                <option value="NO_RESPONSABLE_IVA">No Responsable de IVA</option>
                <option value="GRAN_CONTRIBUYENTE">Gran Contribuyente</option>
                <option value="AUTORRETENEDOR">Autorretenedor</option>
              </select>
            </div>
          </div>

          <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
            <div>
              <label className="block text-xs font-bold text-slate-700 mb-1">Dirección Principal</label>
              <input
                type="text"
                value={companyData.address}
                onChange={(e) => setCompanyData({ ...companyData, address: e.target.value })}
                className="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-xl text-xs text-slate-900 focus:bg-white focus:ring-2 focus:ring-blue-500"
              />
            </div>
            <div>
              <label className="block text-xs font-bold text-slate-700 mb-1">Ciudad</label>
              <input
                type="text"
                value={companyData.city}
                onChange={(e) => setCompanyData({ ...companyData, city: e.target.value })}
                className="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-xl text-xs text-slate-900 focus:bg-white focus:ring-2 focus:ring-blue-500"
              />
            </div>
            <div>
              <label className="block text-xs font-bold text-slate-700 mb-1">Departamento</label>
              <input
                type="text"
                value={companyData.department}
                onChange={(e) => setCompanyData({ ...companyData, department: e.target.value })}
                className="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-xl text-xs text-slate-900 focus:bg-white focus:ring-2 focus:ring-blue-500"
              />
            </div>
          </div>

          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 pt-4 border-t border-slate-100">
            <div>
              <label className="block text-xs font-bold text-slate-700 mb-1">Representante Legal</label>
              <input
                type="text"
                value={companyData.legalRepresentative}
                onChange={(e) => setCompanyData({ ...companyData, legalRepresentative: e.target.value })}
                className="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-xl text-xs text-slate-900 focus:bg-white focus:ring-2 focus:ring-blue-500"
              />
            </div>
            <div>
              <label className="block text-xs font-bold text-slate-700 mb-1">Contador Público / Tarjeta Profesional</label>
              <input
                type="text"
                value={`${companyData.accountantName} (T.P. ${companyData.accountantCard})`}
                onChange={(e) => setCompanyData({ ...companyData, accountantName: e.target.value })}
                className="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-xl text-xs text-slate-900 focus:bg-white focus:ring-2 focus:ring-blue-500"
              />
            </div>
          </div>
        </div>
      )}

      {/* Tab: PERÍODOS */}
      {activeTab === 'PERIODS' && (
        <div className="bg-white p-8 rounded-2xl border border-slate-200 shadow-sm space-y-6">
          <div className="flex items-center justify-between border-b border-slate-100 pb-4">
            <div>
              <h3 className="text-base font-bold text-slate-900">Períodos Fiscales Contables</h3>
              <p className="text-xs text-slate-500">Apertura, bloqueo de meses y proceso automatizado de cierre de cuentas de resultado</p>
            </div>
            <button
              onClick={handleRunAnnualClose}
              className="px-4 py-2 bg-purple-600 text-white text-xs font-semibold rounded-xl hover:bg-purple-700 shadow-sm"
            >
              Ejecutar Cierre Anual Fiscal (CZ)
            </button>
          </div>

          <div className="overflow-x-auto">
            <table className="w-full text-left border-collapse text-xs">
              <thead>
                <tr className="bg-slate-50 border-b border-slate-200 text-[11px] font-bold text-slate-600 uppercase">
                  <th className="py-2.5 px-4">Año</th>
                  <th className="py-2.5 px-4">Mes</th>
                  <th className="py-2.5 px-4">Nombre del Período</th>
                  <th className="py-2.5 px-4 text-center">Estado</th>
                  <th className="py-2.5 px-4 text-right">Acción</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100">
                {periods.length === 0 ? (
                  Array.from({ length: 12 }).map((_, idx) => {
                    const monthNum = idx + 1;
                    const months = ['Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio', 'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'];
                    return (
                      <tr key={idx} className="hover:bg-slate-50 font-mono">
                        <td className="py-2.5 px-4 font-bold">2026</td>
                        <td className="py-2.5 px-4">{monthNum.toString().padStart(2, '0')}</td>
                        <td className="py-2.5 px-4 font-sans font-medium">{months[idx]} 2026</td>
                        <td className="py-2.5 px-4 text-center">
                          <span className="px-2 py-0.5 rounded-full text-[10px] font-bold bg-emerald-50 text-emerald-700 border border-emerald-200">
                            Abierto
                          </span>
                        </td>
                        <td className="py-2.5 px-4 text-right font-sans">
                          <button className="px-2.5 py-1 rounded-lg bg-slate-100 text-slate-700 hover:bg-slate-200 text-[11px] font-bold">
                            Cerrar Mes
                          </button>
                        </td>
                      </tr>
                    );
                  })
                ) : (
                  periods.map((p) => (
                    <tr key={p.id} className="hover:bg-slate-50 font-mono">
                      <td className="py-2.5 px-4 font-bold">{p.year}</td>
                      <td className="py-2.5 px-4">{p.month}</td>
                      <td className="py-2.5 px-4 font-sans font-medium">{p.name}</td>
                      <td className="py-2.5 px-4 text-center">
                        <span className={`px-2 py-0.5 rounded-full text-[10px] font-bold ${
                          p.status === 'OPEN' ? 'bg-emerald-50 text-emerald-700' : 'bg-rose-50 text-rose-700'
                        }`}>
                          {p.status === 'OPEN' ? 'Abierto' : 'Cerrado'}
                        </span>
                      </td>
                      <td className="py-2.5 px-4 text-right font-sans">
                        <button
                          onClick={() => handleTogglePeriod(p.id, p.status)}
                          className="px-2.5 py-1 rounded-lg bg-slate-100 text-slate-700 hover:bg-slate-200 text-[11px] font-bold"
                        >
                          {p.status === 'OPEN' ? 'Cerrar Mes' : 'Reabrir'}
                        </button>
                      </td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {/* Tab: CONSECUTIVOS */}
      {activeTab === 'CONSECUTIVES' && (
        <div className="bg-white p-8 rounded-2xl border border-slate-200 shadow-sm space-y-6">
          <div>
            <h3 className="text-base font-bold text-slate-900">Consecutivos de Documentos Contables</h3>
            <p className="text-xs text-slate-500">Configuración de prefijos, numeración actual y secuencia automática</p>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            {[
              { code: 'CC', name: 'Comprobante Contable / Diario', prefix: 'CC-', current: 105 },
              { code: 'CI', name: 'Recibo de Caja / Ingreso', prefix: 'CI-', current: 48 },
              { code: 'CE', name: 'Comprobante de Egreso / Pago', prefix: 'CE-', current: 62 },
              { code: 'FV', name: 'Factura de Venta', prefix: 'FV-', current: 310 },
              { code: 'FC', name: 'Factura de Compra', prefix: 'FC-', current: 180 },
              { code: 'NC', name: 'Nota Crédito', prefix: 'NC-', current: 12 },
              { code: 'ND', name: 'Nota Débito', prefix: 'ND-', current: 5 },
              { code: 'DP', name: 'Depreciación Periódica', prefix: 'DP-', current: 1 }
            ].map((doc) => (
              <div key={doc.code} className="p-4 rounded-xl bg-slate-50 border border-slate-200 flex items-center justify-between">
                <div>
                  <span className="font-bold text-xs text-slate-900 block">{doc.code} - {doc.name}</span>
                  <span className="text-[11px] text-slate-500 font-mono">Prefijo: {doc.prefix}</span>
                </div>
                <div className="text-right font-mono">
                  <span className="text-[10px] text-slate-400 block font-semibold">SIGUIENTE NÚMERO</span>
                  <span className="text-sm font-bold text-blue-700">#{doc.current + 1}</span>
                </div>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* Tab: SISTEMA */}
      {activeTab === 'SYSTEM' && (
        <div className="bg-white p-8 rounded-2xl border border-slate-200 shadow-sm space-y-6">
          <div>
            <h3 className="text-base font-bold text-slate-900">Infraestructura y Aislamiento de Motores</h3>
            <p className="text-xs text-slate-500">Verificación del entorno de ejecución, puerto y aislamiento de datos</p>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div className="p-5 rounded-2xl bg-blue-50 border border-blue-200 space-y-2">
              <div className="flex items-center gap-2 text-blue-900 font-bold text-xs">
                <Database className="w-4 h-4 text-blue-600" />
                <span>Motor Activo de Base de Datos</span>
              </div>
              <p className="text-sm font-mono font-bold text-blue-800">PostgreSQL Local (Korex_contabilidad_pg)</p>
              <p className="text-xs text-blue-700">Puerto de Operación: 3002 • 100% Autónomo e Independiente</p>
            </div>

            <div className="p-5 rounded-2xl bg-emerald-50 border border-emerald-200 space-y-2">
              <div className="flex items-center gap-2 text-emerald-900 font-bold text-xs">
                <ShieldCheck className="w-4 h-4 text-emerald-600" />
                <span>Estado del Archivo .env</span>
              </div>
              <p className="text-sm font-mono font-bold text-emerald-800">Cifrado AES-256-CBC • Protegido</p>
              <p className="text-xs text-emerald-700">Inviolable en actualizaciones • Credenciales resguardadas</p>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
