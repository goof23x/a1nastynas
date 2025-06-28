<template>
  <span class="relative group inline-block">
    <span class="text-tiffany cursor-pointer">
      <slot name="icon">
        <i class="ti ti-help-circle"></i>
      </slot>
    </span>
    <span class="absolute left-1/2 -translate-x-1/2 mt-2 w-max min-w-[120px] max-w-xs bg-base-200 text-base-content text-sm rounded shadow-lg px-3 py-2 opacity-0 group-hover:opacity-100 group-focus:opacity-100 transition-opacity z-50 pointer-events-none">
      <slot />
    </span>
  </span>
</template> 