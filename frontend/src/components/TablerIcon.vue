<template>
  <span v-html="svg" :class="[$attrs.class]"></span>
</template>

<script setup>
import { computed } from 'vue';
const props = defineProps({ name: String });
const svg = computed(() => {
  // Use Tabler Icons CDN
  return `<svg xmlns='http://www.w3.org/2000/svg' class='icon icon-tabler icon-tabler-${props.name}' width='24' height='24' viewBox='0 0 24 24' stroke-width='2' stroke='currentColor' fill='none' stroke-linecap='round' stroke-linejoin='round'><use href='https://unpkg.com/@tabler/icons@latest/icons/tabler-${props.name}.svg#icon' /></svg>`;
});
</script> 