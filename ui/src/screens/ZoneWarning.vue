<script setup>
import { ref, computed, onMounted, onUnmounted } from 'vue'
import { AlertTriangle, Skull } from 'lucide-vue-next'

const visible = ref(false)
const type = ref(null) // 'out-of-zone' | 'enemy-zone'
const timeRemaining = ref(0)

let timerInterval = null

const config = {
  'out-of-zone': {
    title: 'OUT OF ZONE',
    color: 'red',
    icon: AlertTriangle,
    message: 'Return to the safe zone immediately!'
  },
  'enemy-zone': {
    title: 'IN ENEMY ZONE',
    color: 'orange',
    icon: Skull,
    message: 'Leave this area immediately!'
  }
}

const style = computed(() => (type.value ? config[type.value] : null))

function startTimer(time) {
  clearTimer()
  timeRemaining.value = time ?? 3

  timerInterval = setInterval(() => {
    timeRemaining.value--

    if (timeRemaining.value <= 0) {
      clearTimer()
      triggerDeath()
    }
  }, 1000)
}

function clearTimer() {
  if (timerInterval) {
    clearInterval(timerInterval)
    timerInterval = null
  }
}

function triggerDeath() {
  fetch(`https://${GetParentResourceName()}/zoneDeath`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      reason: type.value
    })
  })

  visible.value = false
  type.value = null
}

function showOutOfZone(time) {
  type.value = 'out-of-zone'
  visible.value = true
  startTimer(time)
}

function showEnemyZone(time) {
  type.value = 'enemy-zone'
  visible.value = true
  startTimer(time)
}

function clearZoneWarning() {
  visible.value = false
  type.value = null
  clearTimer()
}

onMounted(() => {
  window.addEventListener('message', onMessage)
})

onUnmounted(() => {
  window.removeEventListener('message', onMessage)
  clearTimer()
})

function onMessage(event) {
  const { action,time } = event.data || {}

  switch (action) {
    case 'zone:out':
      showOutOfZone(time)
      break

    case 'zone:enemy':
      showEnemyZone(time)
      break

    case 'zone:clear':
      clearZoneWarning()
      break
  }
}
</script>

<template>
  <div v-if="visible" class="zw-root">
    <div class="zw-box" :class="style.color">
      <div class="zw-content">
        <div class="zw-icon pulse" :class="style.color">
          <component :is="style.icon" />
        </div>

        <div class="zw-title" :class="style.color">
          {{ style.title }}
        </div>

        <div class="zw-text">You will die in</div>

        <div
          class="zw-timer"
          :class="[style.color, timeRemaining <= 5 ? 'danger' : '']"
        >
          {{ timeRemaining }}s
        </div>

        <div class="zw-sub">
          {{ style.message }}
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.zw-root {
  position: fixed;
  top: 35%;
  left: 50%;
  transform: translateX(-50%);
  z-index: 100;
}

.zw-box {
  padding: 24px 32px;
  border-radius: 12px;
  border: 2px solid;
  box-shadow: 0 0 30px rgba(0,0,0,0.6);
  animation: slide-down 0.4s ease forwards;
}

.zw-box.red {
  background: rgba(69,10,10,0.95);
  border-color: #ef4444;
  box-shadow: 0 0 40px rgba(239,68,68,0.4);
}

.zw-box.orange {
  background: rgba(67,20,7,0.95);
  border-color: #f97316;
  box-shadow: 0 0 40px rgba(249,115,22,0.4);
}

.zw-title.red,
.zw-timer.red,
.zw-icon.red {
  color: #ef4444;
}

.zw-title.orange,
.zw-timer.orange,
.zw-icon.orange {
  color: #f97316;
}

.zw-content {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 12px;
}

.zw-icon svg {
  width: 64px;
  height: 64px;
}

.zw-title {
  font-size: 18px;
  letter-spacing: 2px;
}

.zw-text {
  color: white;
}

.zw-timer {
  font-size: 56px;
  font-variant-numeric: tabular-nums;
}

.zw-sub {
  font-size: 13px;
  color: #d1d5db;
  text-align: center;
}

@keyframes slide-down {
  from {
    opacity: 0;
    transform: translate(-50%, -20px);
  }
  to {
    opacity: 1;
    transform: translate(-50%, 0);
  }
}

.pulse {
  animation: pulse 1s infinite;
}

@keyframes pulse {
  0% { transform: scale(1); }
  50% { transform: scale(1.2); }
  100% { transform: scale(1); }
}

.danger {
  animation: danger-pulse 0.5s infinite;
}

@keyframes danger-pulse {
  0% { transform: scale(1); }
  50% { transform: scale(1.1); }
  100% { transform: scale(1); }
}
</style>
