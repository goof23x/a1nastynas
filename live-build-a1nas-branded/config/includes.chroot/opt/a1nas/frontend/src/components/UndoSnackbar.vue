<template>
  <div v-if="show" class="fixed bottom-8 left-1/2 -translate-x-1/2 z-50">
    <div class="alert alert-info shadow-lg flex items-center gap-2 max-w-xs">
      <span><i class="ti ti-undo text-tiffany"></i></span>
      <span class="flex-1">{{ message }}</span>
      <button class="btn btn-xs btn-primary" @click="undo">Undo</button>
    </div>
  </div>
</template>

<script setup>
import { ref, watch } from 'vue';
const props = defineProps({ show: Boolean, message: String });
const emit = defineEmits(['undo', 'close']);

function undo() {
  emit('undo');
  emit('close');
}

watch(() => props.show, (val) => {
  if (val) setTimeout(() => emit('close'), 4000);
});
</script> 