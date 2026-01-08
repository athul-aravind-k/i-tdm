<script setup>
import { computed } from 'vue'
import {
  ArrowLeft,
  Trophy,
  Crown,
  Award
} from 'lucide-vue-next'

const props = defineProps({
  payload: {
    type: Object,
    required: true
  }
})
const emit = defineEmits(['close'])

const mode = computed(() => props.payload.mode)
const winningTeam = computed(() => props.payload.winningTeam || 'blue')


function calculateKD(k, d) {
  return d === 0 ? k.toFixed(2) : (k / d).toFixed(2)
}

const sortedBlue = computed(() => {
  const players = props?.payload?.blueTeamPlayers
  if (!Array.isArray(players)) return []
  const result = [...players]
    .filter(p => p != null)
    .sort((a, b) => (b?.kills ?? 0) - (a?.kills ?? 0))
  return result
})

const sortedRed = computed(() => {
  const players = props?.payload?.redTeamPlayers
  if (!Array.isArray(players)) return []
  const result = [...players]
    .filter(p => p != null)
    .sort((a, b) => (b?.kills ?? 0) - (a?.kills ?? 0))
  return result
})

const sortedPlayers = computed(() => {
  const players = props?.payload?.players
  console.log(JSON.stringify(players))
  if (!Array.isArray(players)) return []
  const result = [...players]
    .filter(p => p != null)
    .sort((a, b) => (b?.kills ?? 0) - (a?.kills ?? 0))
  console.log('sortedPlayers:', JSON.stringify(result))
  return result
})
</script>

<template>
  <div class="me-root">
    <button class="me-back" @click="emit('close')">
      <ArrowLeft />
      Close
    </button>

    <template v-if="mode === 'team-deathmatch'">
      <div class="me-victory">
        <Trophy :class="winningTeam" />
        <h1 :class="winningTeam">
          {{ winningTeam === 'blue' ? 'Blue Team' : 'Red Team' }} Victory
        </h1>
        <Trophy :class="winningTeam" />
      </div>

      <div class="me-teams">
        <!-- BLUE -->
        <div class="me-team blue">
          <div class="me-team-header blue">Blue Team</div>

          <div class="me-table-header">
            <span>Player</span>
            <span>Kills</span>
            <span>Deaths</span>
            <span>K/D</span>
          </div>

          <div class="me-scroll">
            <div
              v-for="(p,i) in sortedBlue"
              :key="i"
              class="me-row blue"
            >
              <span>{{ p.name }}</span>
              <span class="green">{{ p.kills }}</span>
              <span class="orange">{{ p.deaths }}</span>
              <span class="cyan">{{ calculateKD(p.kills,p.deaths) }}</span>
            </div>
          </div>
        </div>

        <!-- RED -->
        <div class="me-team red">
          <div class="me-team-header red">Red Team</div>

          <div class="me-table-header">
            <span>Player</span>
            <span>Kills</span>
            <span>Deaths</span>
            <span>K/D</span>
          </div>

          <div class="me-scroll">
            <div
              v-for="(p,i) in sortedRed"
              :key="i"
              class="me-row red"
            >
              <span>{{ p.name }}</span>
              <span class="green">{{ p.kills }}</span>
              <span class="orange">{{ p.deaths }}</span>
              <span class="cyan">{{ calculateKD(p.kills,p.deaths) }}</span>
            </div>
          </div>
        </div>
      </div>
    </template>

    <template v-else>
      <div v-if="sortedPlayers[0]" class="me-winner">
        <Crown />
        <div>
          <h1>{{ sortedPlayers[0].name }}</h1>
          <p>Match Winner</p>
        </div>
      </div>

      <!-- PODIUM -->
      <div class="me-podium">
        <div
          v-for="(p,i) in sortedPlayers.slice(1,3)"
          :key="i"
          class="me-podium-card"
          :class="i === 0 ? 'second' : 'third'"
        >
          <Award />
          <h2>{{ p.name }}</h2>
          <p>K/D {{ calculateKD(p.kills,p.deaths) }}</p>
        </div>
      </div>

      <!-- FULL LEADERBOARD -->
      <div class="me-leaderboard">
        <div class="me-table-header five">
          <span>Rank</span>
          <span>Player</span>
          <span>Kills</span>
          <span>Deaths</span>
          <span>K/D</span>
        </div>

        <div class="me-scroll tall">
          <div
            v-for="(p,i) in sortedPlayers"
            :key="i"
            class="me-row five"
            :class="i < 3 ? `top${i+1}` : ''"
          >
            <span>#{{ i+1 }}</span>
            <span>{{ p.name }}</span>
            <span class="green">{{ p.kills }}</span>
            <span class="orange">{{ p.deaths }}</span>
            <span class="cyan">{{ calculateKD(p.kills,p.deaths) }}</span>
          </div>
        </div>
      </div>
    </template>
  </div>
</template>

<style scoped>
.me-root {
  min-height: 100vh;
  background: linear-gradient(#0a0e1a, #1a1f2e);
  color: white;
  padding: 32px;
}

.me-back {
  display: flex;
  gap: 8px;
  align-items: center;
  background: none;
  border: none;
  color: #9ca3af;
  cursor: pointer;
  margin-bottom: 24px;
}
.me-back svg { width: 18px; height: 18px; }

.me-victory {
  display: flex;
  justify-content: center;
  align-items: center;
  gap: 12px;
  margin-bottom: 40px;
}
.me-victory h1 {
  font-size: 36px;
}
.me-victory .blue { color: #60a5fa; }
.me-victory .red { color: #f87171; }

.me-teams {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 32px;
}

.me-team {
  border-radius: 10px;
  overflow: hidden;
  background: rgba(15,21,32,0.5);
}
.me-team-header {
  padding: 16px;
  font-size: 22px;
}
.me-team-header.blue { background: rgba(59,130,246,0.2); }
.me-team-header.red { background: rgba(239,68,68,0.2); }

.me-table-header {
  display: grid;
  grid-template-columns: 2fr 1fr 1fr 1fr;
  padding: 8px 16px;
  color: #9ca3af;
  border-bottom: 1px solid rgba(255,255,255,0.1);
}
.me-table-header.five {
  grid-template-columns: 1fr 2fr 1fr 1fr 1fr;
}

.me-scroll {
  max-height: 400px;
  overflow-y: auto;
  padding: 12px;
}
.me-scroll.tall {
  max-height: 300px;
}

.me-row {
  display: grid;
  grid-template-columns: 2fr 1fr 1fr 1fr;
  padding: 12px;
  border-radius: 6px;
  margin-bottom: 8px;
}
.me-row.five {
  grid-template-columns: 1fr 2fr 1fr 1fr 1fr;
}

.me-row.blue { background: rgba(59,130,246,0.05); }
.me-row.red { background: rgba(239,68,68,0.05); }

.me-row.top1 { background: rgba(234,179,8,0.15); }
.me-row.top2 { background: rgba(156,163,175,0.15); }
.me-row.top3 { background: rgba(249,115,22,0.15); }

.green { color: #4ade80; }
.orange { color: #fb923c; }
.cyan { color: #22d3ee; }

.me-winner {
  display: flex;
  align-items: center;
  gap: 16px;
  background: rgba(234,179,8,0.2);
  border: 2px solid #facc15;
  padding: 24px;
  border-radius: 12px;
  margin-bottom: 32px;
}
.me-winner svg {
  width: 64px;
  height: 64px;
  color: #facc15;
}
.me-winner h1 {
  font-size: 32px;
}

.me-podium {
  display: flex;
  gap: 24px;
  margin-bottom: 32px;
}
.me-podium-card {
  flex: 1;
  padding: 20px;
  border-radius: 10px;
}
.me-podium-card.second {
  background: rgba(156,163,175,0.2);
}
.me-podium-card.third {
  background: rgba(249,115,22,0.2);
}
</style>
