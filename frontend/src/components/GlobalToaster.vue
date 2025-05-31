<template>
  <div class="fixed bottom-4 left-1/2 -translate-x-1/2 z-50 flex flex-col gap-2 items-center">
    <transition-group name="toast-fade" tag="div">
      <div v-for="(toast, i) in toasts" :key="toast.id" :class="['alert', toast.type === 'success' ? 'alert-success' : toast.type === 'error' ? 'alert-error' : 'alert-info', 'shadow-lg', 'w-full', 'max-w-xs', 'flex', 'items-center', 'gap-2']">
        <span class="text-xl">
          <i :class="toast.icon"></i>
        </span>
        <span class="flex-1">{{ toast.message }}</span>
        <button class="btn btn-xs btn-ghost" @click="remove(i)"><i class="ti ti-x"></i></button>
      </div>
    </transition-group>
  </div>
</template>

<script setup>
import { ref } from 'vue';
const toasts = ref([]);

function showToast({ message, type = 'info', icon = 'ti ti-info-circle', duration = 3500 }) {
  const id = Date.now() + Math.random();
  toasts.value.push({ id, message, type, icon });
  setTimeout(() => removeById(id), duration);
}
function remove(i) { toasts.value.splice(i, 1); }
function removeById(id) {
  const idx = toasts.value.findIndex(t => t.id === id);
  if (idx !== -1) remove(idx);
}

// Expose for global use
if (typeof window !== 'undefined') window.$toast = showToast;
</script>

<style>
.toast-fade-enter-active, .toast-fade-leave-active { transition: opacity 0.3s; }
.toast-fade-enter-from, .toast-fade-leave-to { opacity: 0; }
</style> 