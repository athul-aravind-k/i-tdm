<script setup>
import { ref, watch, onUnmounted } from 'vue'
import {
  AlertCircle,
  CheckCircle,
  Info,
  X
} from 'lucide-vue-next'

const props = defineProps({
  notification: {
    type: Object,
    default: null
  }
})

const emit = defineEmits(['close'])

const visible = ref(false)
let autoCloseTimer = null

watch(
  () => props.notification,
  (val) => {
    if (val) {
      visible.value = true
      startAutoClose()
    } else {
      visible.value = false
      clearAutoClose()
    }
  },
  { immediate: true }
)

function startAutoClose() {
  clearAutoClose()
  autoCloseTimer = setTimeout(() => {
    emit('close')
  }, 4000)
}

function clearAutoClose() {
  if (autoCloseTimer) {
    clearTimeout(autoCloseTimer)
    autoCloseTimer = null
  }
}

onUnmounted(() => {
  clearAutoClose()
})

function getIcon(type) {
  if (type === 'error') return AlertCircle
  if (type === 'success') return CheckCircle
  if (type === 'info') return Info
  return Info
}

function getClass(type) {
  if (type === 'error') return 'error'
  if (type === 'success') return 'success'
  if (type === 'info') return 'info'
  return 'info'
}

function close() {
  emit('close')
}
</script>

<template>
  <div class="notif-root">
    <div
      v-if="notification && visible"
      class="notif-box"
      :class="getClass(notification.type)"
    >
      <component
        :is="getIcon(notification.type)"
        class="notif-icon"
      />

      <span class="notif-text">
        {{ notification.message }}
      </span>

      <button class="notif-close" @click="close">
        <X />
      </button>
    </div>
  </div>
</template>

<style scoped>
.notif-root {
  position: fixed;
  top: 32px;
  left: 50%;
  transform: translateX(-50%);
  z-index: 200;
  pointer-events: none;
}

.notif-box {
  min-width: 300px;
  padding: 14px 20px;
  border-radius: 12px;
  border: 2px solid;
  display: flex;
  align-items: center;
  gap: 12px;
  box-shadow: 0 0 30px rgba(0,0,0,0.6);
  animation: notif-in 0.35s ease forwards;
  pointer-events: auto;
}

.notif-box.error {
  background: rgba(239,68,68,0.9);
  border-color: #dc2626;
  color: white;
}

.notif-box.success {
  background: rgba(34,197,94,0.9);
  border-color: #16a34a;
  color: white;
}

.notif-box.info {
  background: rgba(59,130,246,0.9);
  border-color: #2563eb;
  color: white;
}

.notif-icon {
  width: 20px;
  height: 20px;
  flex-shrink: 0;
}

.notif-text {
  flex: 1;
  font-size: 14px;
}

.notif-close {
  background: none;
  border: none;
  cursor: pointer;
  opacity: 0.8;
  transition: opacity 0.2s ease;
}

.notif-close svg {
  width: 18px;
  height: 18px;
}

.notif-close:hover {
  opacity: 1;
}

@keyframes notif-in {
  from {
    opacity: 0;
    transform: translateY(-20px) scale(0.95);
  }
  to {
    opacity: 1;
    transform: translateY(0) scale(1);
  }
}
</style>
