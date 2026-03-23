"use client";

import { useState, useEffect, useRef } from "react";
import { useAuth } from "@/contexts/AuthContext";
import {
  Plus,
  Car,
  Wrench,
  Gauge,
  Trash2,
  Edit3,
  X,
  ImagePlus,
  Loader2,
} from "lucide-react";
import { getUserCars, addCar, updateCar, deleteCar, CarBuild, CarMod } from "@/services/cars";

export default function GaragePage() {
  const { user } = useAuth();
  const [cars, setCars] = useState<CarBuild[]>([]);
  const [loading, setLoading] = useState(true);
  const [showAddModal, setShowAddModal] = useState(false);
  const [editingCar, setEditingCar] = useState<CarBuild | null>(null);
  const [selectedCar, setSelectedCar] = useState<CarBuild | null>(null);

  useEffect(() => {
    if (!user) return;
    loadCars();
  }, [user]);

  async function loadCars() {
    try {
      const data = await getUserCars(user!.uid);
      setCars(data);
      if (data.length > 0 && !selectedCar) {
        setSelectedCar(data[0]);
      }
    } catch (err) {
      console.error("Error loading cars:", err);
    } finally {
      setLoading(false);
    }
  }

  async function handleDelete(carId: string) {
    if (!confirm("Are you sure you want to delete this build?")) return;
    try {
      await deleteCar(carId);
      const remaining = cars.filter((c) => c.id !== carId);
      setCars(remaining);
      setSelectedCar(remaining.length > 0 ? remaining[0] : null);
    } catch (err) {
      console.error("Error deleting car:", err);
    }
  }

  if (loading) {
    return (
      <div className="flex min-h-[50vh] items-center justify-center">
        <Loader2 size={32} className="animate-spin text-accent" />
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold">My Garage</h1>
          <p className="mt-1 text-sm text-muted">
            {cars.length} build{cars.length !== 1 ? "s" : ""}
          </p>
        </div>
        <button
          onClick={() => { setEditingCar(null); setShowAddModal(true); }}
          className="flex items-center gap-2 rounded-xl bg-accent px-4 py-2.5 text-sm font-medium text-white transition-colors hover:bg-accent-hover"
        >
          <Plus size={18} />
          Add Build
        </button>
      </div>

      {cars.length === 0 ? (
        <div className="flex flex-col items-center justify-center py-20 text-center">
          <Car size={64} className="text-muted/20" />
          <h3 className="mt-4 text-lg font-semibold">Your garage is empty</h3>
          <p className="mt-1 text-sm text-muted">Add your first build to get started</p>
          <button
            onClick={() => setShowAddModal(true)}
            className="mt-4 flex items-center gap-2 rounded-xl bg-accent px-6 py-2.5 text-sm font-medium text-white"
          >
            <Plus size={18} />
            Add Build
          </button>
        </div>
      ) : (
        <div className="grid gap-4 lg:grid-cols-3">
          <div className="space-y-3 lg:col-span-1">
            {cars.map((car) => (
              <button
                key={car.id}
                onClick={() => setSelectedCar(car)}
                className={`w-full overflow-hidden rounded-xl border text-left transition-all ${
                  selectedCar?.id === car.id ? "border-accent bg-accent/5" : "border-border/50 bg-card/30 hover:bg-card/50"
                }`}
              >
                <div className="relative h-28 overflow-hidden">
                  {car.coverPhoto ? (
                    <img src={car.coverPhoto} alt={car.nickname} className="h-full w-full object-cover" />
                  ) : (
                    <div className="h-full w-full bg-gradient-to-br from-accent/10 to-accent/5 flex items-center justify-center">
                      <Car size={28} className="text-muted/30" />
                    </div>
                  )}
                  <div className="absolute inset-0 bg-gradient-to-t from-black/70 to-transparent" />
                  <div className="absolute bottom-2 left-3">
                    <p className="text-sm font-semibold">{car.nickname || `${car.make} ${car.model}`}</p>
                    <p className="text-xs text-zinc-300">{car.year} {car.make} {car.model} {car.trim}</p>
                  </div>
                </div>
              </button>
            ))}
          </div>

          {selectedCar && (
            <div className="space-y-4 lg:col-span-2">
              <div className="relative overflow-hidden rounded-2xl">
                {selectedCar.coverPhoto ? (
                  <img src={selectedCar.coverPhoto} alt={selectedCar.nickname} className="h-64 w-full object-cover" />
                ) : (
                  <div className="h-64 w-full bg-gradient-to-br from-accent/10 to-accent/5 flex items-center justify-center">
                    <Car size={48} className="text-muted/20" />
                  </div>
                )}
                <div className="absolute inset-0 bg-gradient-to-t from-black/60 to-transparent" />
                <div className="absolute bottom-4 left-4">
                  <h2 className="text-xl font-bold">{selectedCar.nickname || `${selectedCar.make} ${selectedCar.model}`}</h2>
                  <p className="text-sm text-zinc-300">{selectedCar.year} {selectedCar.make} {selectedCar.model} {selectedCar.trim}</p>
                </div>
                <div className="absolute right-4 top-4 flex gap-2">
                  <button onClick={() => { setEditingCar(selectedCar); setShowAddModal(true); }} className="flex h-8 w-8 items-center justify-center rounded-lg bg-black/50 backdrop-blur-sm hover:bg-black/70"><Edit3 size={14} /></button>
                  <button onClick={() => handleDelete(selectedCar.id)} className="flex h-8 w-8 items-center justify-center rounded-lg bg-black/50 backdrop-blur-sm hover:bg-red-500/80"><Trash2 size={14} /></button>
                </div>
              </div>

              {selectedCar.photos && selectedCar.photos.length > 1 && (
                <div className="flex gap-2 overflow-x-auto pb-2">
                  {selectedCar.photos.map((photo, i) => (
                    <img key={i} src={photo} alt={`Photo ${i + 1}`} className="h-20 w-28 flex-shrink-0 rounded-lg object-cover" />
                  ))}
                </div>
              )}

              {selectedCar.description && (
                <div className="rounded-xl border border-border/50 bg-card/30 p-4">
                  <p className="text-sm text-muted">{selectedCar.description}</p>
                </div>
              )}

              <div className="rounded-xl border border-border/50 bg-card/30 p-4">
                <h3 className="mb-3 font-semibold flex items-center gap-2"><Gauge size={16} className="text-accent" />Specs</h3>
                <div className="grid grid-cols-2 gap-3 sm:grid-cols-3">
                  {[
                    { label: "Horsepower", value: selectedCar.horsepower ? `${selectedCar.horsepower} HP` : "—" },
                    { label: "Torque", value: selectedCar.torque ? `${selectedCar.torque} lb-ft` : "—" },
                    { label: "Engine", value: selectedCar.engine || "—" },
                    { label: "Drivetrain", value: selectedCar.drivetrain || "—" },
                    { label: "Transmission", value: selectedCar.transmission || "—" },
                    { label: "Weight", value: selectedCar.weight ? `${selectedCar.weight} lbs` : "—" },
                  ].map((spec) => (
                    <div key={spec.label} className="rounded-lg bg-card/50 p-3">
                      <p className="text-xs text-muted">{spec.label}</p>
                      <p className="mt-0.5 text-sm font-medium">{spec.value}</p>
                    </div>
                  ))}
                </div>
              </div>

              <div className="rounded-xl border border-border/50 bg-card/30 p-4">
                <h3 className="mb-3 font-semibold flex items-center gap-2"><Wrench size={16} className="text-accent" />Modifications ({selectedCar.mods?.length || 0})</h3>
                {selectedCar.mods && selectedCar.mods.length > 0 ? (
                  <div className="space-y-2">
                    {selectedCar.mods.map((mod, i) => (
                      <div key={i} className="flex items-center justify-between rounded-lg bg-card/50 px-3 py-2">
                        <span className="text-sm">{mod.name}</span>
                        <span className="rounded-full bg-accent/10 px-2 py-0.5 text-xs text-accent">{mod.category}</span>
                      </div>
                    ))}
                  </div>
                ) : (
                  <p className="text-sm text-muted">No mods added yet</p>
                )}
              </div>
            </div>
          )}
        </div>
      )}

      {showAddModal && (
        <CarFormModal car={editingCar} userId={user!.uid} onClose={() => { setShowAddModal(false); setEditingCar(null); }} onSaved={async () => { setShowAddModal(false); setEditingCar(null); await loadCars(); }} />
      )}
    </div>
  );
}

function CarFormModal({ car, userId, onClose, onSaved }: { car: CarBuild | null; userId: string; onClose: () => void; onSaved: () => void }) {
  const [year, setYear] = useState(car?.year || "");
  const [make, setMake] = useState(car?.make || "");
  const [model, setModel] = useState(car?.model || "");
  const [trim, setTrim] = useState(car?.trim || "");
  const [nickname, setNickname] = useState(car?.nickname || "");
  const [description, setDescription] = useState(car?.description || "");
  const [horsepower, setHorsepower] = useState(car?.horsepower || "");
  const [torque, setTorque] = useState(car?.torque || "");
  const [engine, setEngine] = useState(car?.engine || "");
  const [drivetrain, setDrivetrain] = useState(car?.drivetrain || "");
  const [transmission, setTransmission] = useState(car?.transmission || "");
  const [weight, setWeight] = useState(car?.weight || "");
  const [mods, setMods] = useState<CarMod[]>(car?.mods || []);
  const [newModName, setNewModName] = useState("");
  const [newModCategory, setNewModCategory] = useState("Engine");
  const [photoFiles, setPhotoFiles] = useState<File[]>([]);
  const [photoPreviews, setPhotoPreviews] = useState<string[]>([]);
  const [saving, setSaving] = useState(false);
  const fileInputRef = useRef<HTMLInputElement>(null);

  const modCategories = ["Engine", "Turbo/Supercharger", "Exhaust", "Suspension", "Brakes", "Wheels/Tires", "Exterior", "Interior", "Electronics", "Drivetrain", "Other"];

  function handlePhotoSelect(e: React.ChangeEvent<HTMLInputElement>) {
    const files = Array.from(e.target.files || []);
    setPhotoFiles((prev) => [...prev, ...files]);
    files.forEach((file) => {
      const reader = new FileReader();
      reader.onloadend = () => setPhotoPreviews((prev) => [...prev, reader.result as string]);
      reader.readAsDataURL(file);
    });
  }

  function addMod() {
    if (!newModName.trim()) return;
    setMods((prev) => [...prev, { name: newModName.trim(), category: newModCategory }]);
    setNewModName("");
  }

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setSaving(true);
    try {
      const carData = { ownerId: userId, year, make, model, trim, nickname, description, horsepower, torque, engine, drivetrain, transmission, weight, mods };
      if (car) {
        await updateCar(car.id, carData, photoFiles.length > 0 ? photoFiles : undefined);
      } else {
        await addCar(carData, photoFiles);
      }
      onSaved();
    } catch (err) {
      console.error("Error saving car:", err);
    } finally {
      setSaving(false);
    }
  }

  return (
    <div className="fixed inset-0 z-50 flex items-start justify-center overflow-y-auto p-4 pt-20">
      <div className="absolute inset-0 bg-black/60" onClick={onClose} />
      <div className="relative w-full max-w-2xl rounded-2xl border border-border/50 bg-background p-6 mb-20">
        <div className="flex items-center justify-between">
          <h2 className="text-xl font-bold">{car ? "Edit Build" : "Add a New Build"}</h2>
          <button onClick={onClose} className="text-muted hover:text-foreground"><X size={20} /></button>
        </div>

        <form onSubmit={handleSubmit} className="mt-6 space-y-6">
          <div>
            <label className="mb-2 block text-sm font-medium">Photos</label>
            <input ref={fileInputRef} type="file" accept="image/*" multiple className="hidden" onChange={handlePhotoSelect} />
            <div className="flex flex-wrap gap-2">
              {car?.photos?.map((photo, i) => (<img key={`e-${i}`} src={photo} alt="" className="h-20 w-28 rounded-lg object-cover" />))}
              {photoPreviews.map((p, i) => (<img key={`n-${i}`} src={p} alt="" className="h-20 w-28 rounded-lg object-cover" />))}
              <button type="button" onClick={() => fileInputRef.current?.click()} className="flex h-20 w-28 items-center justify-center rounded-lg border border-dashed border-border/50 text-muted hover:border-accent/50 hover:text-foreground"><ImagePlus size={20} /></button>
            </div>
          </div>

          <div className="grid grid-cols-2 gap-3 sm:grid-cols-4">
            <div><label className="mb-1 block text-xs text-muted">Year</label><input type="text" value={year} onChange={(e) => setYear(e.target.value)} required placeholder="2002" className="w-full rounded-lg border border-border bg-card/50 px-3 py-2 text-sm outline-none focus:border-accent" /></div>
            <div><label className="mb-1 block text-xs text-muted">Make</label><input type="text" value={make} onChange={(e) => setMake(e.target.value)} required placeholder="Nissan" className="w-full rounded-lg border border-border bg-card/50 px-3 py-2 text-sm outline-none focus:border-accent" /></div>
            <div><label className="mb-1 block text-xs text-muted">Model</label><input type="text" value={model} onChange={(e) => setModel(e.target.value)} required placeholder="Silvia" className="w-full rounded-lg border border-border bg-card/50 px-3 py-2 text-sm outline-none focus:border-accent" /></div>
            <div><label className="mb-1 block text-xs text-muted">Trim</label><input type="text" value={trim} onChange={(e) => setTrim(e.target.value)} placeholder="Spec-R" className="w-full rounded-lg border border-border bg-card/50 px-3 py-2 text-sm outline-none focus:border-accent" /></div>
          </div>

          <div><label className="mb-1 block text-xs text-muted">Nickname</label><input type="text" value={nickname} onChange={(e) => setNickname(e.target.value)} placeholder="Project Midnight" className="w-full rounded-lg border border-border bg-card/50 px-3 py-2 text-sm outline-none focus:border-accent" /></div>

          <div><label className="mb-1 block text-xs text-muted">Description</label><textarea value={description} onChange={(e) => setDescription(e.target.value)} rows={2} placeholder="Tell us about your build..." className="w-full resize-none rounded-lg border border-border bg-card/50 px-3 py-2 text-sm outline-none focus:border-accent" /></div>

          <div>
            <h3 className="mb-2 text-sm font-medium">Specs</h3>
            <div className="grid grid-cols-2 gap-3 sm:grid-cols-3">
              <div><label className="mb-1 block text-xs text-muted">HP</label><input type="text" value={horsepower} onChange={(e) => setHorsepower(e.target.value)} placeholder="350" className="w-full rounded-lg border border-border bg-card/50 px-3 py-2 text-sm outline-none focus:border-accent" /></div>
              <div><label className="mb-1 block text-xs text-muted">Torque</label><input type="text" value={torque} onChange={(e) => setTorque(e.target.value)} placeholder="300" className="w-full rounded-lg border border-border bg-card/50 px-3 py-2 text-sm outline-none focus:border-accent" /></div>
              <div><label className="mb-1 block text-xs text-muted">Engine</label><input type="text" value={engine} onChange={(e) => setEngine(e.target.value)} placeholder="SR20DET" className="w-full rounded-lg border border-border bg-card/50 px-3 py-2 text-sm outline-none focus:border-accent" /></div>
              <div><label className="mb-1 block text-xs text-muted">Drivetrain</label><input type="text" value={drivetrain} onChange={(e) => setDrivetrain(e.target.value)} placeholder="RWD" className="w-full rounded-lg border border-border bg-card/50 px-3 py-2 text-sm outline-none focus:border-accent" /></div>
              <div><label className="mb-1 block text-xs text-muted">Transmission</label><input type="text" value={transmission} onChange={(e) => setTransmission(e.target.value)} placeholder="6-Speed Manual" className="w-full rounded-lg border border-border bg-card/50 px-3 py-2 text-sm outline-none focus:border-accent" /></div>
              <div><label className="mb-1 block text-xs text-muted">Weight (lbs)</label><input type="text" value={weight} onChange={(e) => setWeight(e.target.value)} placeholder="2800" className="w-full rounded-lg border border-border bg-card/50 px-3 py-2 text-sm outline-none focus:border-accent" /></div>
            </div>
          </div>

          <div>
            <h3 className="mb-2 text-sm font-medium">Modifications ({mods.length})</h3>
            {mods.length > 0 && (
              <div className="mb-3 space-y-1.5">
                {mods.map((mod, i) => (
                  <div key={i} className="flex items-center justify-between rounded-lg bg-card/50 px-3 py-2">
                    <div className="flex items-center gap-2">
                      <span className="text-sm">{mod.name}</span>
                      <span className="rounded-full bg-accent/10 px-2 py-0.5 text-xs text-accent">{mod.category}</span>
                    </div>
                    <button type="button" onClick={() => setMods((prev) => prev.filter((_, idx) => idx !== i))} className="text-muted hover:text-red-400"><X size={14} /></button>
                  </div>
                ))}
              </div>
            )}
            <div className="flex gap-2">
              <input type="text" value={newModName} onChange={(e) => setNewModName(e.target.value)} placeholder="Mod name" onKeyDown={(e) => e.key === "Enter" && (e.preventDefault(), addMod())} className="flex-1 rounded-lg border border-border bg-card/50 px-3 py-2 text-sm outline-none focus:border-accent" />
              <select value={newModCategory} onChange={(e) => setNewModCategory(e.target.value)} className="rounded-lg border border-border bg-card/50 px-3 py-2 text-sm outline-none focus:border-accent">
                {modCategories.map((cat) => (<option key={cat} value={cat}>{cat}</option>))}
              </select>
              <button type="button" onClick={addMod} className="rounded-lg bg-accent/10 px-3 py-2 text-sm font-medium text-accent hover:bg-accent/20">Add</button>
            </div>
          </div>

          <div className="flex items-center justify-end gap-3 border-t border-border/30 pt-4">
            <button type="button" onClick={onClose} className="rounded-xl px-4 py-2.5 text-sm font-medium text-muted hover:text-foreground">Cancel</button>
            <button type="submit" disabled={saving || !year || !make || !model} className="flex items-center gap-2 rounded-xl bg-accent px-6 py-2.5 text-sm font-medium text-white transition-colors hover:bg-accent-hover disabled:opacity-50">
              {saving ? <Loader2 size={16} className="animate-spin" /> : car ? "Save Changes" : "Add to Garage"}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}
