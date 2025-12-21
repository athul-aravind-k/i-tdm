<script setup>
import { ref, computed, watch } from 'vue'
import { ArrowLeft, Crown, UserX, Settings } from 'lucide-vue-next'

const props = defineProps({
  payload: {
    type: Object,
    required: true
  }
})

// let props = {
//   payload: { "map": "map1", "matchId": 1, "playerId": 1, "mapTable": { "time": 5, "maxMembers": 10, "id": 1, "blueTeam": { "AIE74953": { "name": "insane blue", "source": 2 } }, "weapon": "assault", "bucketId": 2, "creatorId": 1, "redTeam": { "AIE73953": { "name": "insane gwak", "source": 1 } }, "started": false, "creator": "InsanE", "password": "" } }
// }

const emit = defineEmits(['change', 'close'])

const map = ref(null)
const matchId = ref(null)
const playerId = ref(null)
const match = ref(null)
const currentTeam = ref(null)

const isOwner = computed(() => {
  return match.value && playerId.value === match.value.creatorId
})


watch(
  () => props.payload,
  (newPayload) => {
    if (!newPayload) return

    map.value = newPayload.map
    matchId.value = newPayload.matchId
    playerId.value = newPayload.playerId
    match.value = newPayload.mapTable
  },
  { immediate: true }
)

function getResourceName() {
  return typeof GetParentResourceName === 'function'
    ? GetParentResourceName()
    : null
}

function joinTeam(team) {
  if (!match.value) return
  currentTeam.value = team
  fetch(`https://${getResourceName()}/join-tdm`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      map: map.value,
      matchId: String(matchId.value),
      bucketId: match.value.bucketId,
      team
    })
  })
}

function kickPlayer(team, id) {
  if (!isOwner.value) return

  fetch(`https://${getResourceName()}/kick-tdm-player`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      map: map.value,
      matchId: matchId.value,
      team,
      playerId: id
    })
  })
}

function updateWeapon(value) {
  fetch(`https://${getResourceName()}/tdm-update-settings`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      map: map.value,
      matchId: matchId.value,
      weapon: value
    })
  })
}

function updateTime(value) {
  fetch(`https://${getResourceName()}/tdm-update-settings`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      map: map.value,
      matchId: matchId.value,
      time: Number(value)
    })
  })
}

function updateMemberCount(value) {
  fetch(`https://${getResourceName()}/tdm-update-settings`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      map: map.value,
      matchId: matchId.value,
      maxMembers: Number(value)
    })
  })
}

function startMatch() {
  if (!isOwner.value) return

  fetch(`https://${getResourceName()}/start-tdm`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      map: map.value,
      matchId: matchId.value,
      bucketId: match.value.bucketId
    })
  })

  emit('close')
}

function goBack() {
  emit('change', 'main')
}

</script>

<template>
  <div class="tdm-root">
    <!-- Background -->
    <div class="tdm-bg">
      <img :src="'/assets/bg/team.png'" alt="Background" />
      <div class="tdm-overlay"></div>
    </div>

    <div class="tdm-content">
      <div class="tdm-wrapper">
        <!-- Header -->
        <div class="tdm-header tdm-anim-left">
          <button class="tdm-back" @click="goBack">
            <ArrowLeft />
            Back
          </button>

          <h1 class="tdm-title tdm-anim-down">
            {{ match.mapName }}
          </h1>

          <div class="tdm-spacer"></div>
        </div>

        <div class="tdm-grid">
          <!-- BLUE TEAM -->
          <div class="tdm-team blue tdm-anim-left delay-1">
            <div class="tdm-team-header blue">Blue</div>

            <div class="tdm-roster">
              <div v-for="player in Object.values(match.blueTeam || {})" :key="player.source" class="tdm-player">
                <div class="tdm-player-left">
                  <Crown v-if="isOwner" class="tdm-crown" />
                  <span>{{ player.name }}</span>
                  <span
                    v-if="player.source === playerId"
                    class="tdm-you blue"
                  >(You)</span>
                </div>

                <button v-if="isOwner && player.source !== match.creatorId" class="tdm-kick"
                  @click="kickPlayer('blue', player.source)">
                  <UserX />
                </button>
              </div>
            </div>

            <button class="tdm-join blue" :disabled="!!currentPlayer" @click="joinTeam('blue')">
              {{ currentTeam === 'blue' ? 'Current Team' : 'Join' }}
            </button>
          </div>

          <!-- RED TEAM -->
          <div class="tdm-team red tdm-anim-left delay-2">
            <div class="tdm-team-header red">Red</div>

            <div class="tdm-roster">
              <div v-for="player in Object.values(match.redTeam || {})" :key="player.source" class="tdm-player">
                <div class="tdm-player-left">
                  <Crown v-if="isOwner" class="tdm-crown" />
                  <span>{{ player.name }}</span>
                  <span
                    v-if="player.source === playerId"
                    class="tdm-you red"
                  >(You)</span>
                </div>

                <button v-if="isOwner && player.source !== match.creatorId" class="tdm-kick"
                  @click="kickPlayer('red', player.source)">
                  <UserX />
                </button>
              </div>
            </div>

            <button class="tdm-join red" :disabled="!!currentPlayer" @click="joinTeam('red')">
              {{ currentTeam === 'red' ? 'Current Team' : 'Join' }}
            </button>
          </div>

          <!-- SETTINGS -->
          <div class="tdm-settings tdm-anim-right delay-3">
            <div class="tdm-settings-header">
              <Settings />
              Settings
            </div>

            <div class="tdm-settings-body">
              <label>
                Total Time
                <select :value="match.time" :disabled="!isOwner" @change="updateTime($event.target.value)">
                  <option v-for="n in [5, 10, 15, 20, 30]" :key="n" :value="n">
                    {{ n }} Min
                  </option>
                </select>
              </label>

              <label>
                Weapon Class
                <select :value="match.weapon" @change="updateWeapon($event.target.value)" :disabled="!isOwner">
                  <option value="assault">Assault</option>
                  <option value="sniper">Sniper</option>
                  <option value="shotgun">Shotgun</option>
                  <option value="smg">SMG</option>
                </select>
              </label>

              <label>
                Max Players
                <select :value="match.maxMembers" @change="updateMemberCount($event.target.value)" :disabled="!isOwner">
                  <option v-for="n in [4, 6, 8, 10, 12]" :key="n" :value="n">
                    {{ n }}
                  </option>
                </select>
              </label>

              <button v-if="isOwner" class="tdm-start" @click="startMatch">
                Start
              </button>

              <p v-else class="tdm-wait">
                Waiting for host to start…
              </p>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.tdm-root {
  height: 100vh;
  background: black;
  font-family: Arial, Helvetica, sans-serif;
}

.tdm-bg {
  position: absolute;
  inset: 0;
}

.tdm-bg img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.tdm-overlay {
  position: absolute;
  inset: 0;
  background: rgba(0, 0, 0, 0.5);
}

.tdm-content {
  position: relative;
  z-index: 2;
  padding: 32px;
}

.tdm-wrapper {
  max-width: 1400px;
  margin: auto;
}

.tdm-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 24px;
}

.tdm-back {
  display: flex;
  gap: 6px;
  background: none;
  border: none;
  color: #ccc;
  cursor: pointer;
  align-items: center;
}

.tdm-title {
  color: white;
  font-size: 22px;
}

.tdm-grid {
  display: grid;
  grid-template-columns: 1fr 1fr 1fr;
  gap: 24px;
}

.tdm-team {
  background: rgba(0, 0, 0, 0.4);
  border: 1px solid rgba(255, 255, 255, 0.1);
}

.tdm-team-header {
  padding: 12px;
  text-align: center;
  font-style: italic;
}

.tdm-team-header.blue {
  color: #60a5fa;
}

.tdm-team-header.red {
  color: #f87171;
}

.tdm-roster {
  padding: 12px;
  min-height: 350px;
}

.tdm-player {
  display: flex;
  justify-content: space-between;
  padding: 8px;
  background: rgba(0, 0, 0, 0.4);
  margin-bottom: 6px;
}

.tdm-player-left {
  display: flex;
  gap: 6px;
  color: white;
  font-size: 13px;
  align-items: center;
}

.tdm-crown {
  width: 14px;
  color: gold;
}

.tdm-you.blue {
  color: #60a5fa;
}

.tdm-you.red {
  color: #f87171;
}

.tdm-kick {
  background: none;
  border: none;
  color: #f87171;
  cursor: pointer;
}

/* ===== JOIN ===== */
.tdm-join {
  width: 100%;
  padding: 10px;
  border: none;
  color: white;
  cursor: pointer;
}

.tdm-join.blue {
  background: #2563eb;
}

.tdm-join.red {
  background: #dc2626;
}

/* ===== SETTINGS ===== */
.tdm-settings {
  background: rgba(0, 0, 0, 0.4);
  border: 1px solid rgba(255, 255, 255, 0.1);
}

.tdm-settings-header {
  padding: 12px;
  display: flex;
  gap: 6px;
  color: white;
  align-items: center;
}

.tdm-settings-body {
  padding: 16px;
}

.tdm-settings-body label {
  display: block;
  color: #aaa;
  margin-bottom: 12px;
}

.tdm-settings-body select {
  width: 100%;
  margin-top: 4px;
  padding: 6px;
  background: black;
  color: white;
  border: 1px solid #333;
}

.tdm-start {
  margin-top: 16px;
  width: 100%;
  padding: 10px;
  background: white;
  border: none;
  cursor: pointer;
}

.tdm-wait {
  text-align: center;
  color: #777;
  margin-top: 16px;
}

@keyframes tdm-left {
  from {
    opacity: 0;
    transform: translateX(-30px);
  }

  to {
    opacity: 1;
    transform: translateX(0);
  }
}

@keyframes tdm-right {
  from {
    opacity: 0;
    transform: translateX(30px);
  }

  to {
    opacity: 1;
    transform: translateX(0);
  }
}

@keyframes tdm-down {
  from {
    opacity: 0;
    transform: translateY(-20px);
  }

  to {
    opacity: 1;
    transform: translateY(0);
  }
}

.tdm-anim-left {
  animation: tdm-left .6s ease forwards;
}

.tdm-anim-right {
  animation: tdm-right .6s ease forwards;
}

.tdm-anim-down {
  animation: tdm-down .6s ease forwards;
}

.delay-1 {
  animation-delay: .1s;
}

.delay-2 {
  animation-delay: .2s;
}

.delay-3 {
  animation-delay: .3s;
}
</style>
