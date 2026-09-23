'use client';

import React, { useState } from 'react';
import Link from 'next/link';
import { usePathname, useRouter } from 'next/navigation';
import {
  LayoutDashboard,
  BookOpen,
  Users,
  Receipt,
  Landmark,
  CreditCard,
  ShoppingBag,
  Building2,
  FileBarChart,
  FileText,
  Percent,
  ArrowLeftRight,
  HelpCircle,
  Settings,
  LogOut,
  ChevronRight,
  Database,
  Calendar,
  Menu as MenuIcon,
  X
} from 'lucide-react';

const MENU_ITEMS = [
  { href: '/dashboard', label: 'Tablero Ejecutivo', icon: LayoutDashboard },
  { href: '/dashboard/puc', label: 'Plan de Cuentas (PUC)', icon: BookOpen },
  { href: '/dashboard/third-parties', label: 'Terceros y Clientes', icon: Users },
  { href: '/dashboard/journal-entries', label: 'Comprobantes y Asientos', icon: Receipt },
  { href: '/dashboard/treasury', label: 'Tesorería y Bancos', icon: Landmark },
  { href: '/dashboard/receivables', label: 'Cartera (CxC)', icon: CreditCard },
  { href: '/dashboard/payables', label: 'Proveedores (CxP)', icon: ShoppingBag },
  { href: '/dashboard/fixed-assets', label: 'Activos Fijos', icon: Building2 },
  { href: '/dashboard/reports', label: 'Estados Financieros', icon: FileBarChart },
  { href: '/dashboard/reports/books', label: 'Libros Oficiales', icon: FileText },
  { href: '/dashboard/taxes', label: 'Impuestos y DIAN (Exógena)', icon: Percent },
  { href: '/dashboard/interfaces', label: 'Interfaces e Importación', icon: ArrowLeftRight },
  { href: '/dashboard/manual', label: 'Manual Operativo', icon: HelpCircle },
  { href: '/dashboard/settings', label: 'Configuración', icon: Settings },
];

export default function DashboardLayout({ children }: { children: React.ReactNode }) {
  const pathname = usePathname();
  const router = useRouter();
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);

  const handleLogout = () => {
    document.cookie = 'auth_token=; path=/; expires=Thu, 01 Jan 1970 00:00:00 GMT';
    router.push('/login');
  };

  return (
    <div className="min-h-screen bg-slate-50 flex">
      {/* Sidebar Lateral */}
      <aside className={`fixed inset-y-0 left-0 z-50 w-64 bg-slate-900 text-slate-300 flex flex-col border-r border-slate-800 transition-transform lg:translate-x-0 ${mobileMenuOpen ? 'translate-x-0' : '-translate-x-full lg:static'}`}>
        
        {/* Brand Header */}
        <div className="h-16 flex items-center justify-between px-6 border-b border-slate-800 bg-slate-950/50">
          <Link href="/dashboard" className="flex items-center gap-3">
            <div className="w-9 h-9 rounded-xl bg-blue-600 flex items-center justify-center text-white font-bold shadow-md shadow-blue-500/20">
              <Building2 className="w-5 h-5" />
            </div>
            <div>
              <span className="font-bold text-white text-base tracking-tight block leading-tight">Korex</span>
              <span className="text-[10px] text-blue-400 font-medium uppercase tracking-wider block">Contabilidad NIIF</span>
            </div>
          </Link>
          <button onClick={() => setMobileMenuOpen(false)} className="lg:hidden text-slate-400 hover:text-white">
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* Navigation Links */}
        <nav className="flex-1 overflow-y-auto px-3 py-4 space-y-1">
          {MENU_ITEMS.map((item) => {
            const Icon = item.icon;
            const isActive = pathname === item.href;
            return (
              <Link
                key={item.href}
                href={item.href}
                onClick={() => setMobileMenuOpen(false)}
                className={`flex items-center gap-3 px-3.5 py-2.5 rounded-xl text-xs font-medium transition-all group ${
                  isActive
                    ? 'bg-blue-600 text-white shadow-md shadow-blue-600/20'
                    : 'text-slate-400 hover:bg-slate-800/60 hover:text-slate-200'
                }`}
              >
                <Icon className={`w-4 h-4 transition-colors ${isActive ? 'text-white' : 'text-slate-400 group-hover:text-blue-400'}`} />
                <span className="flex-1 truncate">{item.label}</span>
                {isActive && <ChevronRight className="w-3.5 h-3.5 text-blue-200" />}
              </Link>
            );
          })}
        </nav>

        {/* User Footer */}
        <div className="p-4 border-t border-slate-800 bg-slate-950/40">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-3 truncate">
              <div className="w-8 h-8 rounded-full bg-blue-500/20 text-blue-400 flex items-center justify-center font-bold text-xs border border-blue-500/30">
                AD
              </div>
              <div className="truncate">
                <p className="text-xs font-semibold text-white truncate">Administrador</p>
                <p className="text-[10px] text-slate-500 truncate">admin@korex.com.co</p>
              </div>
            </div>
            <button
              onClick={handleLogout}
              title="Cerrar sesión"
              className="p-1.5 rounded-lg text-slate-400 hover:text-rose-400 hover:bg-rose-500/10 transition-colors"
            >
              <LogOut className="w-4 h-4" />
            </button>
          </div>
        </div>
      </aside>

      {/* Contenedor Principal */}
      <div className="flex-1 flex flex-col min-w-0">
        
        {/* Top Header */}
        <header className="h-16 bg-white border-b border-slate-200 flex items-center justify-between px-4 lg:px-8 sticky top-0 z-40">
          <div className="flex items-center gap-3">
            <button onClick={() => setMobileMenuOpen(true)} className="lg:hidden p-2 text-slate-600 hover:bg-slate-100 rounded-lg">
              <MenuIcon className="w-5 h-5" />
            </button>
            <div>
              <h2 className="text-sm font-bold text-slate-800 leading-tight">EMPRESA DEMO CONTABLE S.A.S.</h2>
              <p className="text-[11px] text-slate-500">NIT: 900.123.456-8 • Régimen Ordinario</p>
            </div>
          </div>

          <div className="flex items-center gap-3">
            {/* Indicador de Motor Activo */}
            <div className="hidden sm:inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full bg-blue-50 text-blue-700 text-xs font-semibold border border-blue-200">
              <Database className="w-3.5 h-3.5 text-blue-600" />
              <span>PostgreSQL Local</span>
            </div>

            {/* Período Fiscal */}
            <div className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full bg-emerald-50 text-emerald-700 text-xs font-semibold border border-emerald-200">
              <Calendar className="w-3.5 h-3.5 text-emerald-600" />
              <span>Año 2026 - Período Abierto</span>
            </div>
          </div>
        </header>

        {/* Contenido Dinámico de la Página */}
        <main className="flex-1 p-4 lg:p-8 max-w-7xl w-full mx-auto">
          {children}
        </main>
      </div>
    </div>
  );
}
