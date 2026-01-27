<script setup>
import { ref, computed, reactive, onMounted } from 'vue'
import {
  Users,
  Clock,
  Target,
  Skull,
  Heart,
  Shield
} from 'lucide-vue-next'

let audioUnlocked = false

const killSounds = [
  new Audio('assets/sounds/kill-1.ogg'),
  new Audio('assets/sounds/kill-2.ogg'),
  new Audio('assets/sounds/kill-3.ogg'),
  new Audio('assets/sounds/kill-4.ogg'),
  new Audio('assets/sounds/kill-5.ogg')
]

killSounds.forEach(sound => {
  sound.volume = 0.6
  sound.preload = 'auto'
})

window.addEventListener('click', unlockAudio, { once: true })
window.addEventListener('keydown', unlockAudio, { once: true })

const prevKills = ref(0)
const isTDM = ref(false)
const visible = ref(false)
const timerVisible = ref(false)
const timeRemaining = ref(0)
const blueTeamKills = ref(0)
const redTeamKills = ref(0)

const killStreak = ref(0)
const showKillEffect = ref(false)
const STREAK_DURATION = 6000
const streakTimeLeft = ref(0)

let streakInterval = null

let resetTimer = null


let timerInterval = null
let timerEnd = 0



const stats = reactive({
  hp: 0,
  armor: 0,
  kills: 0,
  deaths: 0,
  ammo: 0,
  clip: 0
})

const kd = computed(() =>
  stats.deaths === 0
    ? stats.kills
    : (stats.kills / stats.deaths).toFixed(2)
)

const hpPer = computed(() => {
  const minHp = 100
  const maxHp = 200
  const hp = Math.min(Math.max(stats.hp, minHp), maxHp)
  return (((hp - minHp) / (maxHp - minHp)) * 100).toFixed(2)
})


const minutes = computed(() =>
  Math.floor(timeRemaining.value / 60)
)

const seconds = computed(() =>
  timeRemaining.value % 60
)

const timerState = computed(() => {
  if (timeRemaining.value > 120) return 'green'
  if (timeRemaining.value > 60) return 'yellow'
  return 'red'
})

const healthState = computed(() => {
  if (hpPer.value > 60) return 'green'
  if (hpPer.value > 30) return 'yellow'
  return 'red'
})

const streakPercent = computed(() =>
  ((streakTimeLeft.value / STREAK_DURATION) * 100).toFixed(2)
)


onMounted(() => {
  window.addEventListener('message', (event) => {
    const data = event.data

    switch (data.type) {
      case 'toggle-hud':
        visible.value = data.message.bool
        if (data?.message.isTdm) {
          isTDM.value = true
        }
        if (data.message.bool) {
          startTimerMs(data.message.totalTime)
          // Reset scores when showing HUD
          blueTeamKills.value = 0
          redTeamKills.value = 0
          prevKills.value = 0
          stats.kills = 0
          stats.deaths = 0
        } else {
          stopTimer()
          isTDM.value = false
        }
        break

      case 'update-stats': {
        const incomingKills = data.message.kills ?? stats.kills
        Object.assign(stats, data.message)
        if (incomingKills > prevKills.value) {
          const diff = incomingKills - prevKills.value
          for (let i = 0; i < diff; i++) {
            onKill()
          }
        }
        prevKills.value = stats.kills
        break
      }

      case 'kill-msg-tdm':
        redTeamKills.value = data?.message?.redKills
        blueTeamKills.value = data?.message?.blueKills
        break
    }
  })
})

function startTimerMs(ms) {
  stopTimer()

  timerVisible.value = true
  timerEnd = Date.now() + ms

  tick()
  timerInterval = setInterval(tick, 1000)
}

function tick() {
  const remainingMs = timerEnd - Date.now()

  if (remainingMs <= 0) {
    stopTimer()
    return
  }

  timeRemaining.value = Math.ceil(remainingMs / 1000)
}

function stopTimer() {
  if (timerInterval) {
    clearInterval(timerInterval)
    timerInterval = null
  }

  timerVisible.value = false
  timeRemaining.value = 0
}

function playKillSound(streak) {
  const index = Math.min(streak, 5) - 1
  const sound = killSounds[index]

  if (!sound) return

  sound.currentTime = 0
  sound.play().catch(() => { })
}


function triggerKillEffect() {
  showKillEffect.value = false
  requestAnimationFrame(() => {
    showKillEffect.value = true
  })
}

function onKill() {
  if (resetTimer) clearTimeout(resetTimer)
  if (streakInterval) clearInterval(streakInterval)

  killStreak.value = Math.min(killStreak.value + 1, 5)

  triggerKillEffect()
  playKillSound(killStreak.value)

  streakTimeLeft.value = STREAK_DURATION
  const start = Date.now()

  streakInterval = setInterval(() => {
    const elapsed = Date.now() - start
    streakTimeLeft.value = Math.max(STREAK_DURATION - elapsed, 0)

    if (streakTimeLeft.value <= 0) {
      clearInterval(streakInterval)
      streakInterval = null
    }
  }, 16)

  resetTimer = setTimeout(() => {
    killStreak.value = 0
    showKillEffect.value = false
    streakTimeLeft.value = 0

    if (streakInterval) {
      clearInterval(streakInterval)
      streakInterval = null
    }
  }, STREAK_DURATION)
}


function unlockAudio() {
  if (audioUnlocked) return

  killSounds.forEach(s => {
    s.play().then(() => {
      s.pause()
      s.currentTime = 0
    }).catch(() => { })
  })

  audioUnlocked = true
}

</script>

<template>
  <div v-if="visible" class="hud-root">
    <div class="hud-top">
      <div v-if="isTDM" class="hud-teams">
        <div class="team blue">
          <div class="icon">
            <Users />
          </div>
          <div>
            <div class="label">Blue Team</div>
            <div class="value">{{ blueTeamKills }}</div>
          </div>
        </div>

        <div class="team red">
          <div class="icon">
            <Users />
          </div>
          <div>
            <div class="label">Red Team</div>
            <div class="value">{{ redTeamKills }}</div>
          </div>
        </div>
      </div>

      <div v-if="timerVisible" class="hud-timer" :class="timerState">
        <div class="timer-icon">
          <Clock />
        </div>
        <div class="timer-time">
          {{ String(minutes).padStart(2, '0') }}:{{
            String(seconds).padStart(2, '0')
          }}
        </div>
      </div>

      <div class="hud-stats">
        <div class="stat">
          <div class="stat-icon green">
            <Target />
          </div>
          <div class="stat-label-container">
            <div class="label">Kills</div>
            <div class="value">{{ stats.kills }}</div>
          </div>
        </div>

        <div class="divider"></div>

        <div class="stat">
          <div class="stat-icon red">
            <Skull />
          </div>
          <div class="stat-label-container">
            <div class="label">Deaths</div>
            <div class="value">{{ stats.deaths }}</div>
          </div>
        </div>

        <div class="divider"></div>

        <div class="stat-kd">
          <div class="label">K/D</div>
          <div class="value">{{ kd }}</div>
        </div>
      </div>
    </div>

    <div class="hud-bottom">
      <div class="bar-row">
        <div class="bar-icon red">
          <Heart />
        </div>
        <div class="bar">
          <div class="fill" :class="healthState" :style="{ width: hpPer + '%' }" />
        </div>
      </div>

      <div class="bar-row">
        <div class="bar-icon blue">
          <Shield />
        </div>
        <div class="bar">
          <div class="fill blue" :style="{ width: stats.armor + '%' }" />
        </div>
      </div>
    </div>

    <div class="hud-bottom-right">
      <span class="mag-count">{{ stats.clip }}</span>
      <span class="clip-count">{{ stats.ammo }}</span>
    </div>

    <div v-if="showKillEffect && killStreak > 0" class="kill-effect-wrapper" :class="`streak-${killStreak}`">
      <div class="kill-hex">
        <div class="kill-ring"></div>
        <div class="kill-core">
          <span class="kill-text">{{ killStreak }}</span>
        </div>
      </div>

      <div class="streak-bar">
        <div class="streak-bar-fill" :style="{ width: streakPercent + '%' }"></div>
      </div>
    </div>


  </div>

</template>

<style scoped>
.hud-root {
  position: fixed;
  inset: 0;
  pointer-events: none;
  font-family: Arial, Helvetica, sans-serif;
  color: white;
}

/* ---------------- TOP HUD ---------------- */
.hud-top {
  padding: 24px;
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
}

.hud-teams {
  display: flex;
  gap: 16px;
}

.hud-bottom-right {
  padding: 12px 24px;
  background: rgba(17, 24, 39, 0.8);
  border: 1px solid rgba(55, 65, 81, 0.5);
  border-radius: 10px;
  position: fixed;
  right: 25px;
  bottom: 32px;
  height: 40px;
  font-weight: 600;
}

.mag-count {
  font-size: 40px;
}

.clip-count {
  font-size: 25px;
  margin-bottom: 5px;
  margin-left: 2px;
  color: #8f969f;
}

/* ---------------- TEAMS ---------------- */
.team {
  display: flex;
  gap: 10px;
  padding: 12px 20px;
  border-radius: 10px;
  border: 1px solid;
}

.team.blue {
  background: rgba(59, 130, 246, 0.2);
  border-color: rgba(59, 130, 246, 0.3);
}

.team.red {
  background: rgba(239, 68, 68, 0.2);
  border-color: rgba(239, 68, 68, 0.3);
}

.team .icon {
  padding: 8px;
  border-radius: 6px;
}

.team.blue .icon {
  background: #3b82f6;
}

.team.red .icon {
  background: #ef4444;
}

.team .label {
  font-size: 11px;
  text-transform: uppercase;
  letter-spacing: 1px;
}

.team.blue .label {
  color: #93c5fd;
}

.team.red .label {
  color: #fca5a5;
}

.team .value {
  font-size: 22px;
  font-variant-numeric: tabular-nums;
}

/* ---------------- TIMER ---------------- */
.hud-timer {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 12px 24px;
  border-radius: 10px;
  border: 1px solid;
}

.hud-timer.green {
  color: #4ade80;
  border-color: rgba(34, 197, 94, 0.3);
}

.hud-timer.yellow {
  color: #facc15;
  border-color: rgba(234, 179, 8, 0.3);
}

.hud-timer.red {
  color: #f87171;
  border-color: rgba(239, 68, 68, 0.3);
}

.timer-icon {
  padding: 6px;
  background: #1f2937;
  border-radius: 6px;
  display: flex;
}

.timer-time {
  font-size: 28px;
  font-variant-numeric: tabular-nums;
}

/* ---------------- STATS ---------------- */
.hud-stats {
  display: flex;
  align-items: center;
  gap: 16px;
  padding: 12px 24px;
  background: rgba(17, 24, 39, 0.8);
  border: 1px solid rgba(55, 65, 81, 0.5);
  border-radius: 10px;
}

.stat {
  display: flex;
  gap: 8px;
}

.stat-kd {
  display: flex;
  flex-direction: column;
}

.stat-label-container {
  display: flex;
  flex-direction: column;
  justify-content: center;
}

.stat-icon {
  padding: 8px;
  border-radius: 6px;
}

.stat-icon.green {
  background: #22c55e;
}

.stat-icon.red {
  background: #ef4444;
}

.divider {
  width: 2px;
  height: 40px;
  background: #a8aeb7;
}

.label {
  font-size: 11px;
  color: #9ca3af;
  text-transform: uppercase;
}

.value {
  font-size: 20px;
  font-variant-numeric: tabular-nums;
}

/* ---------------- BOTTOM HUD ---------------- */
.hud-bottom {
  position: fixed;
  bottom: 32px;
  left: 50%;
  transform: translateX(-50%);
  width: 380px;
  background: rgba(17, 24, 39, 0.9);
  border: 1px solid rgba(55, 65, 81, 0.6);
  border-radius: 10px;
  padding: 12px 16px;
}

.bar-row {
  display: flex;
  align-items: center;
  gap: 10px;
}

.bar-row+.bar-row {
  margin-top: 10px;
}

.bar-icon {
  width: 16px;
  height: 16px;
  border-radius: 4px;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 3px;
}

.bar-icon.red {
  background: rgba(239, 68, 68, 0.8);
}

.bar-icon.blue {
  background: rgba(59, 130, 246, 0.8);
}

.bar {
  flex: 1;
  height: 8px;
  background: #1f2937;
  border-radius: 999px;
  overflow: hidden;
}

.fill {
  height: 100%;
  transition: width 0.3s ease-out;
  border-radius: 999px;
}

.fill.green {
  background: linear-gradient(to right, #16a34a, #22c55e);
}

.fill.yellow {
  background: linear-gradient(to right, #ca8a04, #eab308);
}

.fill.red {
  background: linear-gradient(to right, #dc2626, #ef4444);
}

.fill.blue {
  background: linear-gradient(to right, #2563eb, #3b82f6);
}

/* ================= KILL EFFECT ================= */

.kill-effect-wrapper {
  position: fixed;
  left: 50%;
  bottom: 140px;
  transform: translateX(-50%);
  z-index: 45;
  pointer-events: none;
  display: flex;
  justify-content: center;
  flex-direction: column;
  align-items: center;
}

.kill-hex {
  width: 200px;
  height: 200px;
  position: relative;
  clip-path: polygon(25% 6%, 75% 6%,
      100% 50%,
      75% 94%, 25% 94%,
      0% 50%);
  border: 2px solid rgba(255, 40, 40, 0.85);
  box-shadow: 0 0 35px rgba(255, 0, 0, 0.9);
  animation: popInAggressive 0.25s cubic-bezier(0.2, 1.8, 0.4, 1);
}

.kill-ring {
  position: absolute;
  inset: 14px;
  border-radius: 50%;
  border: 3px solid rgba(255, 30, 30, 0.95);
  animation: spinFast 1s linear infinite;
  box-shadow: 0 0 40px rgba(255, 0, 0, 1);
}

.kill-core {
  position: absolute;
  inset: 48px;
  background: radial-gradient(circle at center, #ff3b3b, #7a0000);
  clip-path: polygon(50% 0%,
      85% 25%,
      70% 100%,
      30% 100%,
      15% 25%);
  display: grid;
  place-items: center;
  box-shadow: 0 0 45px rgba(255, 0, 0, 1);
}

.kill-text {
  font-weight: 900;
  font-size: 22px;
  letter-spacing: 3px;
  color: white;
}

/* ---------------- STREAK SCALE ---------------- */
.streak-1 {
  transform: scale(0.9);
}

.streak-2 {
  transform: scale(1.05);
}

.streak-3 {
  transform: scale(1.15);
  filter: drop-shadow(0 0 30px red);
  animation: shake 0.18s linear;
}

.streak-4 {
  transform: scale(1.25);
  filter: drop-shadow(0 0 50px crimson);
  animation: shake 0.18s linear;
}

.streak-5 {
  transform: scale(1.35);
  filter: drop-shadow(0 0 80px red);
  animation: bloodPulse 0.6s infinite alternate;
}

/* ================= STREAK TIMER BAR ================= */

.streak-bar {
  width: 160px;
  height: 6px;
  margin-top: 12px;
  background: rgba(80, 0, 0, 0.6);
  border-radius: 999px;
  overflow: hidden;
  box-shadow: 0 0 12px rgba(255, 0, 0, 0.6);
}

.streak-bar-fill {
  height: 100%;
  background: linear-gradient(to right,
      #ff1a1a,
      #ff6b6b);
  transition: width 0.05s linear;
  border-radius: 999px;
}


/* ---------------- ANIMATIONS ---------------- */

@keyframes spinFast {
  from {
    transform: rotate(0deg);
  }

  to {
    transform: rotate(360deg);
  }
}

@keyframes popInAggressive {
  0% {
    opacity: 0;
    transform: scale(0.3) translateY(40px);
    filter: blur(4px);
  }

  60% {
    opacity: 1;
    transform: scale(1.35) translateY(-5px);
    filter: blur(0);
  }

  100% {
    transform: scale(1);
  }
}

@keyframes shake {
  0% {
    transform: translateX(0);
  }

  20% {
    transform: translateX(-3px);
  }

  40% {
    transform: translateX(3px);
  }

  60% {
    transform: translateX(-2px);
  }

  80% {
    transform: translateX(2px);
  }

  100% {
    transform: translateX(0);
  }
}

@keyframes bloodPulse {
  from {
    transform: scale(1.3);
  }

  to {
    transform: scale(1.38);
  }
}
</style>
