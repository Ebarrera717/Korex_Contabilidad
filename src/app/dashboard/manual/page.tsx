'use client';

import React, { useState } from 'react';
import {
  HelpCircle,
  Search,
  BookOpen,
  ShieldCheck,
  Receipt,
  Wallet,
  CreditCard,
  Building2,
  FileBarChart,
  ArrowLeftRight,
  Package,
  Award,
  ChevronRight,
  Code,
  ShieldAlert,
  Sparkles
} from 'lucide-react';
import { MANUAL_MODULES, ManualModule, ManualSubmodule } from '@/data/manual/modules';

const ICON_MAP: Record<string, any> = {
  ShieldCheck,
  BookOpen,
  Receipt,
  Wallet,
  CreditCard,
  Building2,
  FileBarChart,
  ArrowLeftRight,
  Package,
  Award
};

export default function ManualPage() {
  const [selectedModule, setSelectedModule] = useState<ManualModule>(MANUAL_MODULES[0]);
  const [selectedSubmodule, setSelectedSubmodule] = useState<ManualSubmodule | null>(
    MANUAL_MODULES[0]?.submodules[0] || null
  );
  const [searchTerm, setSearchTerm] = useState('');

  const handleSelectModule = (mod: ManualModule) => {
    setSelectedModule(mod);
    setSelectedSubmodule(mod.submodules[0] || null);
  };

  const filteredModules = MANUAL_MODULES.filter((m) => {
    const term = searchTerm.toLowerCase();
    const titleMatch = m.title.toLowerCase().includes(term);
    const descMatch = m.description.toLowerCase().includes(term);
    const subMatch = m.submodules.some(
      (s) => s.title.toLowerCase().includes(term) || s.description.toLowerCase().includes(term)
    );
    return titleMatch || descMatch || subMatch;
  });

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 bg-white p-6 rounded-2xl border border-slate-200 shadow-sm">
        <div>
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-xl bg-blue-100 text-blue-600 flex items-center justify-center font-bold">
              <HelpCircle className="w-5 h-5" />
            </div>
            <div>
              <h1 className="text-xl font-bold text-slate-900">Manual de Funcionamiento del Sistema</h1>
              <p className="text-xs text-slate-500">Guía operativa interactiva, arquitectura técnica, reglas contables y normatividad NIIF / DIAN</p>
            </div>
          </div>
        </div>
        <div className="w-full sm:w-72">
          <div className="relative">
            <Search className="w-4 h-4 text-slate-400 absolute left-3.5 top-1/2 -translate-y-1/2" />
            <input
              type="text"
              placeholder="Buscar en el manual..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              className="w-full pl-10 pr-4 py-2 bg-slate-50 border border-slate-200 rounded-xl text-xs text-slate-900 focus:outline-none focus:ring-2 focus:ring-blue-500"
            />
          </div>
        </div>
      </div>

      {/* Main Interactive Browser */}
      <div className="grid grid-cols-1 lg:grid-cols-12 gap-6 items-start">
        {/* Modules Sidebar (4 cols) */}
        <div className="lg:col-span-4 bg-white rounded-2xl border border-slate-200 shadow-sm p-4 space-y-2">
          <h3 className="text-xs font-bold text-slate-400 uppercase tracking-wider px-2 mb-2">Módulos del Sistema</h3>
          <div className="space-y-1.5 max-h-[700px] overflow-y-auto pr-1">
            {filteredModules.map((mod) => {
              const Icon = ICON_MAP[mod.icon] || BookOpen;
              const isSelected = selectedModule.id === mod.id;
              return (
                <button
                  key={mod.id}
                  onClick={() => handleSelectModule(mod)}
                  className={`w-full text-left p-3 rounded-xl text-xs font-medium transition-all flex items-start gap-3 ${
                    isSelected
                      ? 'bg-blue-600 text-white shadow-md shadow-blue-500/20'
                      : 'text-slate-700 hover:bg-slate-50 border border-transparent'
                  }`}
                >
                  <div className={`p-1.5 rounded-lg shrink-0 ${isSelected ? 'bg-white/20 text-white' : 'bg-slate-100 text-slate-600'}`}>
                    <Icon className="w-4 h-4" />
                  </div>
                  <div className="flex-1 min-w-0">
                    <p className="font-bold truncate">{mod.title}</p>
                    <p className={`text-[11px] line-clamp-1 mt-0.5 ${isSelected ? 'text-blue-100' : 'text-slate-400'}`}>
                      {mod.submodules.length} temas detallados
                    </p>
                  </div>
                  <ChevronRight className={`w-4 h-4 shrink-0 mt-1 ${isSelected ? 'text-white' : 'text-slate-300'}`} />
                </button>
              );
            })}
          </div>
        </div>

        {/* Content Viewer (8 cols) */}
        <div className="lg:col-span-8 space-y-6">
          {/* Submodules Navigation Tabs */}
          <div className="bg-white p-4 rounded-2xl border border-slate-200 shadow-sm flex items-center gap-2 overflow-x-auto">
            {selectedModule.submodules.map((sub) => {
              const isSelected = selectedSubmodule?.id === sub.id;
              return (
                <button
                  key={sub.id}
                  onClick={() => setSelectedSubmodule(sub)}
                  className={`px-3.5 py-2 rounded-xl text-xs font-bold whitespace-nowrap transition-all ${
                    isSelected
                      ? 'bg-slate-900 text-white shadow-sm'
                      : 'bg-slate-50 text-slate-600 hover:bg-slate-100 border border-slate-200'
                  }`}
                >
                  {sub.title}
                </button>
              );
            })}
          </div>

          {/* Submodule Detail Card */}
          {selectedSubmodule && (
            <div className="bg-white p-8 rounded-2xl border border-slate-200 shadow-sm space-y-6 animate-fadeIn">
              <div className="border-b border-slate-100 pb-4">
                <span className="text-[10px] font-bold text-blue-600 uppercase tracking-wider">{selectedModule.title}</span>
                <h2 className="text-xl font-bold text-slate-900 mt-1">{selectedSubmodule.title}</h2>
                <p className="text-xs text-slate-600 mt-2 leading-relaxed">{selectedSubmodule.description}</p>
              </div>

              {/* Technical Details */}
              {selectedSubmodule.technicalDetails && selectedSubmodule.technicalDetails.length > 0 && (
                <div className="space-y-3">
                  <div className="flex items-center gap-2 text-slate-900 font-bold text-xs uppercase tracking-wider">
                    <Code className="w-4 h-4 text-blue-600" />
                    <span>Especificaciones Técnicas y Arquitectura</span>
                  </div>
                  <div className="bg-slate-50 rounded-xl p-4 border border-slate-200 space-y-2">
                    {selectedSubmodule.technicalDetails.map((detail, idx) => (
                      <div key={idx} className="flex items-start gap-2 text-xs text-slate-700">
                        <span className="text-blue-500 font-bold">•</span>
                        <span>{detail}</span>
                      </div>
                    ))}
                  </div>
                </div>
              )}

              {/* Rules & Constraints */}
              {selectedSubmodule.rules && selectedSubmodule.rules.length > 0 && (
                <div className="space-y-3">
                  <div className="flex items-center gap-2 text-slate-900 font-bold text-xs uppercase tracking-wider">
                    <ShieldAlert className="w-4 h-4 text-amber-600" />
                    <span>Reglas de Negocio y Restricciones Obligatorias</span>
                  </div>
                  <div className="bg-amber-50/60 rounded-xl p-4 border border-amber-200/60 space-y-2">
                    {selectedSubmodule.rules.map((rule, idx) => (
                      <div key={idx} className="flex items-start gap-2 text-xs text-amber-900 font-medium">
                        <span className="text-amber-600 font-bold">⚠️</span>
                        <span>{rule}</span>
                      </div>
                    ))}
                  </div>
                </div>
              )}
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
