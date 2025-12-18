<script setup>
import { ref, reactive, onMounted } from 'vue'

/* =========================
   HUD STATE
========================= */
const visible = ref(false)

const stats = reactive({
  hp: 200,
  armor: 0,
  kills: 0,
  deaths: 0,
  ammo: 0,
  clip: 0
})

/* =========================
   TIMER STATE
========================= */
const timerVisible = ref(false)
const timeText = ref('00 : 00')
const timerPercent = ref(100)
let timerTimeout = null

/* =========================
   Helpers
========================= */
function healthPercent() {
  return Math.max(0, Math.min(100, (stats.hp / 200) * 100))
}

function healthClass() {
  const hp = healthPercent()
  if (hp <= 10) return 'health-red'
  if (hp <= 25) return 'health-orange'
  if (hp <= 50) return 'health-yellow'
  if (hp <= 75) return 'health-light-yellow'
  return 'health-green'
}

function formatTime(ms) {
  if (ms <= 0) return '00 : 00'
  const m = Math.floor((ms % (1000 * 60 * 60)) / (1000 * 60))
  const s = Math.floor((ms % (1000 * 60)) / 1000)
  return `${m} : ${s < 10 ? '0' : ''}${s}`
}

/* =========================
   TIMER LOGIC
========================= */
function startTimer(time, totalTime) {
  stopTimer()

  timerVisible.value = true
  const end = Date.now() + time

  const update = () => {
    const remaining = end - Date.now()
    timerPercent.value = Math.max(
      0,
      Math.round((remaining / totalTime) * 100)
    )
    timeText.value = formatTime(remaining)

    if (remaining <= 0) {
      stopTimer()
      return
    }

    timerTimeout = setTimeout(update, 1000)
  }

  update()
}

function stopTimer() {
  timerVisible.value = false
  timeText.value = '00 : 00'
  timerPercent.value = 0

  if (timerTimeout) {
    clearTimeout(timerTimeout)
    timerTimeout = null
  }
}

/* =========================
   FiveM Message Listener
========================= */
onMounted(() => {
  window.addEventListener('message', (event) => {
    const data = event.data

    switch (data.type) {
      case 'toggle-hud':
        visible.value = data.message.bool
        if (!data.message.bool) stopTimer()
        break

      case 'update-stats':
        Object.assign(stats, data.message)
        break

      case 'toggle-timer':
        if (data.message.bool) {
          startTimer(data.message.time, data.message.totalTime)
        } else {
          stopTimer()
        }
        break
    }
  })
})
</script>

<template>
  <!-- HUD -->
  <div v-show="visible">

    <!-- HEALTH / ARMOR -->
    <div class="progress-bars">
      <div class="stats-container">
        <span id="armor-count">
          <img class="stats-img" src="/assets/armor.png" />
          {{ stats.armor }}
        </span>

        <span id="health-count">
          <img class="stats-img" src="/assets/hp.png" />
          {{ Math.round(healthPercent()) }}
        </span>
      </div>

      <div class="bar-containers">
        <div class="armor-progress-bar">
          <div
            class="armor-progress"
            :style="{ width: stats.armor + '%' }"
          ></div>
        </div>

        <div class="health-progress-bar">
          <div
            id="health-bar"
            class="health-progress"
            :class="healthClass()"
            :style="{ width: healthPercent() + '%' }"
          ></div>
        </div>
      </div>

      <!-- AMMO -->
      <div class="ammo-container">
        <span id="clip-ammo">
          {{ stats.clip < 10 ? '0' + stats.clip : stats.clip }}
        </span>
        <span id="total-ammo">
          {{ stats.ammo }}
        </span>
      </div>
    </div>

    <!-- K / D -->
    <div class="kd-numbers">
      <img class="kd-image" src="/assets/kill-count.png" />
      <span id="kill-count" class="kd-number">
        {{ stats.kills }}
      </span><br />

      <img class="kd-image" src="/assets/death-count.png" />
      <span id="death-count" class="kd-number">
        {{ stats.deaths }}
      </span>
    </div>

    <!-- TIMER -->
    <div v-show="timerVisible" class="timer-container">
      <div class="timer-border">
        <div
          class="timer-inner"
          :style="{
            background: `conic-gradient(
              ${timerPercent <= 30 ? '#FF0000'
              : timerPercent <= 60 ? '#FF6B00'
              : timerPercent <= 80 ? '#EBFF00'
              : '#00ff47'}
              ${timerPercent}%,
              rgba(255,255,255,0) ${timerPercent}%
            )`
          }"
        ></div>
      </div>

      <img class="line" src="/assets/line.png" />
      <p id="timer" class="timer">
        {{ timeText }}
      </p>
    </div>

  </div>
</template>
