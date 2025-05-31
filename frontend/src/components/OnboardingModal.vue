<template>
  <div v-if="show" class="fixed inset-0 bg-black bg-opacity-60 flex items-center justify-center z-50">
    <div class="bg-base-100 rounded-xl shadow-lg p-8 max-w-md w-full text-center">
      <img src="/a1nas.png" alt="A1Nas Logo" class="mx-auto mb-4 h-16 w-16 rounded" />
      <h2 class="text-2xl font-bold text-tiffany mb-2">Welcome to A1Nas!</h2>
      <p class="mb-4 text-base-content">Your simple, modern NAS. Use the sidebar to navigate. All main actions are one click away. Look for <span class="text-tiffany">?</span> icons for help.</p>
      <button class="btn btn-primary w-full" @click="$emit('close')">Get Started</button>
    </div>
  </div>
</template>

<script setup>
const props = defineProps({ show: Boolean });
</script> 