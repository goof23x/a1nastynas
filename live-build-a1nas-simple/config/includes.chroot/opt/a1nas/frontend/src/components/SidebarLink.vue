<template>
  <router-link :to="'/' + label.toLowerCase()" class="flex items-center gap-3 px-3 py-3 rounded-lg transition-colors hover:bg-tiffany/10 hover:text-tiffany min-h-[44px]" active-class="bg-tiffany/20 text-tiffany">
    <TablerIcon :name="icon" class="w-5 h-5" />
    <span class="font-medium">{{ label }}</span>
  </router-link>
</template>

<script setup>
import TablerIcon from './TablerIcon.vue';
const props = defineProps({
  icon: String,
  label: String,
});
</script> 