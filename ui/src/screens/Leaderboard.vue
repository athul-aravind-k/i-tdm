<script setup>
import { ref, computed, onMounted } from 'vue'
import {
  ArrowLeft,
  Trophy,
  Medal,
  Target,
  Skull,
  TrendingUp
} from 'lucide-vue-next'

const players = ref([])
const currentPlayerName = ref('')
const loading = ref(true)

const emit = defineEmits(['change'])

function getResourceName() {
  return window.GetParentResourceName
    ? GetParentResourceName()
    : 'dev'
}

async function fetchLeaderboard() {
  try {
    const response = await fetch(`https://${getResourceName()}/get-leaderboard`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      }
    })
    const data = await response.json()
    players.value = data.players || []
    currentPlayerName.value = data.playerName || ''
  } catch (error) {
    console.error('Failed to fetch leaderboard:', error)
  } finally {
    loading.value = false
  }
}

const sortedPlayers = computed(() =>
  [...players.value].sort((a, b) => b.kills - a.kills)
)

function getKD(player) {
  if (player.deaths === 0) return player.kills.toFixed(2)
  return (player.kills / player.deaths).toFixed(2)
}

function goBack() {
  emit('change','main')
}

onMounted(() => {
  fetchLeaderboard()
})
</script>

<template>
  <div class="lb-root">
    <!-- Background -->
    <div class="lb-bg"></div>

    <div class="lb-content">
      <div class="lb-wrapper">
        <!-- Header -->
        <div class="lb-header">
          <button class="lb-back" @click="goBack">
            <ArrowLeft />
            Back
          </button>

          <h1 class="lb-title lb-anim-down">
            <Trophy />
            Leaderboard
          </h1>

          <div class="lb-spacer"></div>
        </div>

        <!-- Loading State -->
        <div v-if="loading" class="lb-loading">
          <p>Loading leaderboard...</p>
        </div>

        <!-- Empty State -->
        <div v-else-if="sortedPlayers.length === 0" class="lb-empty">
          <p>No players on the leaderboard yet</p>
          <small>Play matches to see your stats!</small>
        </div>

        <template v-else>
          <!-- Podium -->
          <div class="lb-podium">
            <!-- 2nd -->
            <div v-if="sortedPlayers[1]" class="lb-podium-item second lb-anim-up delay-2">
              <div class="lb-podium-icon silver">
                <Medal />
              </div>
              <div class="lb-podium-card silver">
                <p>{{ sortedPlayers[1].name }}</p>
                <span>
                  <Target /> {{ sortedPlayers[1].kills }}
                </span>
                <small>K/D {{ getKD(sortedPlayers[1]) }}</small>
              </div>
              <div class="lb-podium-bar silver"></div>
            </div>

            <!-- 1st -->
            <div v-if="sortedPlayers[0]" class="lb-podium-item first lb-anim-up delay-1">
              <div class="lb-podium-icon gold">
                <Trophy />
              </div>
              <div class="lb-podium-card gold">
                <p>{{ sortedPlayers[0].name }}</p>
                <span>
                  <Target /> {{ sortedPlayers[0].kills }}
                </span>
                <small>K/D {{ getKD(sortedPlayers[0]) }}</small>
              </div>
              <div class="lb-podium-bar gold"></div>
            </div>

            <!-- 3rd -->
            <div v-if="sortedPlayers[2]" class="lb-podium-item third lb-anim-up delay-3">
              <div class="lb-podium-icon bronze">
                <Medal />
              </div>
              <div class="lb-podium-card bronze">
                <p>{{ sortedPlayers[2].name }}</p>
                <span>
                  <Target /> {{ sortedPlayers[2].kills }}
                </span>
                <small>K/D {{ getKD(sortedPlayers[2]) }}</small>
              </div>
              <div class="lb-podium-bar bronze"></div>
            </div>
          </div>

          <!-- Table -->
          <div class="lb-table llb-table-scroll delay-4">
          <div class="lb-table-head">
            <div>Rank</div>
            <div>Player</div>
            <div class="table-head-icon">
              <Target /> Kills
            </div>
            <div class="table-head-icon">
              <Skull /> Deaths
            </div>
            <div class="table-head-icon">
              <TrendingUp /> K/D
            </div>
          </div>

          <div v-for="(player, i) in sortedPlayers" :key="i" class="lb-row" :class="[
            `rank-${i + 1}`,
            player.name === currentPlayerName ? 'is-you' : ''
          ]">
            <div class="lb-rank">
              <span v-if="i === 0">
                <Trophy />
              </span>
              <span v-else-if="i === 1">
                <Medal />
              </span>
              <span v-else-if="i === 2">
                <Medal />
              </span>
              <span v-else>#{{ i + 1 }}</span>
            </div>
            <div class="lb-name">{{ player.name }}</div>
            <div class="lb-kills">{{ player.kills }}</div>
            <div class="lb-deaths">{{ player.deaths }}</div>
            <div class="lb-kd">{{ getKD(player) }}</div>
          </div>
        </div>
        </template>
      </div>
    </div>
  </div>
</template>

<style scoped>
.lb-root {
  height: 100vh;
  background: linear-gradient(135deg, #111, #000, #111111da);
  font-family: Arial, Helvetica, sans-serif;
  color: white;
  overflow: hidden;
}

.lb-table-scroll {
  flex: 1;
  overflow-y: auto;
  margin-top: 24px;
  padding-right: 6px;
}


.lb-bg {
  position: absolute;
  inset: 0;
  background-image:
    linear-gradient(rgba(255, 255, 255, 0.03) 1px, transparent 1px),
    linear-gradient(90deg, rgba(255, 255, 255, 0.03) 1px, transparent 1px);
  background-size: 60px 60px;
  opacity: 0.4;
}


.lb-content {
  position: relative;
  z-index: 2;
  padding: 10px;
  height: 100%;
  display: flex;
  justify-content: center;
}

.lb-wrapper {
  max-width: 1100px;
  flex: 1;
  display: flex;
  flex-direction: column;
}

.lb-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 48px;
}

.lb-back {
  display: flex;
  align-items: center;
  gap: 8px;
  background: none;
  border: none;
  color: #ccc;
  cursor: pointer;
}

.lb-title {
  display: flex;
  align-items: center;
  gap: 12px;
  font-size: 36px;
}

.lb-title svg {
  color: #facc15;
}

.lb-spacer {
  width: 120px;
}

/* ===== PODIUM ===== */
.lb-podium {
  display: flex;
  gap: 24px;
  margin-bottom: 48px;
  justify-content: space-between;
  gap: 24px;
  margin-bottom: 48px;
}

.lb-podium-item {
  display: flex;
  flex-direction: column;
  align-items: center;
  width: 30%;
}

.lb-podium-icon {
  width: 96px;
  height: 96px;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  margin-bottom: 16px;
}

.lb-podium-icon svg {
  width: 48px;
  height: 48px;
}

.gold {
  background: linear-gradient(#facc15, #ca8a04);
}

.silver {
  background: linear-gradient(#d1d5db, #6b7280);
}

.bronze {
  background: linear-gradient(#fb923c, #9a3412);
}

.lb-podium-card {
  width: 100%;
  text-align: center;
  padding: 16px;
  border-radius: 8px;
  margin-bottom: 8px;
}

.lb-podium-card span {
  display: flex;
  justify-content: center;
  gap: 6px;
  align-items: center;
}

.lb-podium-card.gold {
  padding: 1rem;
  border-width: 2px;
  border-style: solid;
  border-color: rgba(234, 178, 8, 0.952);
  background: linear-gradient(
    rgba(234, 178, 8, 0.274),
    transparent
  );

  transition: all 200ms ease;
}

.lb-podium-card.silver {
  padding: 1rem;
  border-width: 2px;
  border-style: solid;
  background: linear-gradient(
    rgba(156, 163, 175, 0.2),
    transparent
  );
  border-color: rgba(156, 163, 175, 0.5); 

  transition: all 200ms ease;
}

.lb-podium-card.bronze {
  padding: 1rem;
  border-width: 2px;
  border-style: solid;
  background: linear-gradient(
    rgba(234, 88, 12, 0.2),
    transparent
  );
  border-color: rgba(234, 88, 12, 0.5);

  transition: all 200ms ease;
}

.lb-podium-bar {
  width: 100%;
  border-radius: 6px 6px 0 0;
}

.lb-podium-bar.gold {
  height: 82px;
  background: rgba(250, 204, 21, 0.3);
}

.lb-podium-bar.silver {
  height: 56px;
  background: rgba(209, 213, 219, 0.3);
}

.lb-podium-bar.bronze {
  height: 30px;
  background: rgba(251, 146, 60, 0.3);
}

/* ===== TABLE ===== */
.lb-table {
  background: rgba(0, 0, 0, 0.6);
  border: 1px solid rgba(255, 255, 255, 0.2);
  border-radius: 10px;
  overflow: hidden;
  overflow: hidden;
  overflow-y: auto;
  max-height: 40vh;
}

.lb-table-head,
.lb-row {
  display: grid;
  grid-template-columns: 1fr 3fr 1fr 1fr 1fr;
  gap: 12px;
  padding: 14px 16px;
  align-items: center;
}

.lb-table-head {
  background: rgb(44, 44, 44);
  font-size: 14px;
  color: #aaa;
  position: sticky;
  top: 0;
  z-index: 5;
}

.lb-row {
  border-top: 1px solid rgba(255, 255, 255, 0.1);
}

.lb-row:hover {
  background: rgba(255, 255, 255, 0.08);
}

.lb-kills {
  color: #4ade80;
}

.lb-deaths {
  color: #f87171;
}

.lb-kd {
  color: #22d3ee;
}

/* ===== ANIMATIONS ===== */
@keyframes lb-up {
  from {
    opacity: 0;
    transform: translateY(30px);
  }

  to {
    opacity: 1;
    transform: translateY(0);
  }
}

@keyframes lb-down {
  from {
    opacity: 0;
    transform: translateY(-20px);
  }

  to {
    opacity: 1;
    transform: translateY(0);
  }
}

@keyframes lb-fade {
  from {
    opacity: 0;
  }

  to {
    opacity: 1;
  }
}

.lb-anim-up {
  animation: lb-up 0.6s ease forwards;
}

.lb-anim-down {
  animation: lb-down 0.6s ease forwards;
}

.lb-anim-fade {
  animation: lb-fade 0.6s ease forwards;
}

.delay-1 {
  animation-delay: 0.1s;
}

.delay-2 {
  animation-delay: 0.2s;
}

.delay-3 {
  animation-delay: 0.3s;
}

.delay-4 {
  animation-delay: 0.4s;
}

.lb-row.rank-1 {
  background: linear-gradient(to right,
      rgba(234, 179, 8, 0.22),
      rgba(234, 179, 8, 0.08),
      transparent);
  border-left: 3px solid rgba(234, 179, 8, 0.8);
}

.lb-row.rank-2 {
  background: linear-gradient(to right,
      rgba(156, 163, 175, 0.22),
      rgba(156, 163, 175, 0.08),
      transparent);
  border-left: 3px solid rgba(156, 163, 175, 0.8);
}

.lb-row.rank-3 {
  background: linear-gradient(to right,
      rgba(234, 88, 12, 0.22),
      rgba(234, 88, 12, 0.08),
      transparent);
  border-left: 3px solid rgba(234, 88, 12, 0.8);
}

.lb-row.rank-1 .lb-rank svg {
  color: #facc15;
}

.lb-row.rank-2 .lb-rank svg {
  color: #d1d5db;
}

.lb-row.rank-3 .lb-rank svg {
  color: #fb923c;
}

.lb-row:hover {
  background-blend-mode: overlay;
}

.lb-row.is-you {
  position: relative;
  box-shadow: inset 0 0 0 1px rgba(34, 211, 238, 0.6);
  background-image:
    linear-gradient(
      to right,
      rgba(34, 211, 238, 0.18),
      rgba(34, 211, 238, 0.06),
      transparent
    );
}

/* small glow accent */
.lb-row.is-you::before {
  content: "";
  position: absolute;
  left: 0;
  top: 0;
  bottom: 0;
  width: 4px;
  background: linear-gradient(
    to bottom,
    rgba(34, 211, 238, 1),
    rgba(34, 211, 238, 0.4)
  );
}

.first {
  margin-top: 0;
}

.second {
  margin-top: 25px;
}

.third {
  margin-top: 52px;
}

.table-head-icon {
  display: flex;
  gap: 5px;
  align-items: center;
}

.lb-loading {
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 60px 0;
  color: #888;
  font-size: 18px;
}

.lb-empty {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 60px 0;
  color: #888;
  gap: 8px;
}
</style>
