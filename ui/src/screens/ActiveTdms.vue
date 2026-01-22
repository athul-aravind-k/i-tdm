<script setup>
import { ref, computed } from 'vue'
import {
  ArrowLeft,
  Lock,
  Users,
  Shield,
  Search
} from 'lucide-vue-next'
import { notificationStore } from '../components/uiNotificationStore'

const props = defineProps({
  payload: Object
})
const emit = defineEmits(['change','close'])

const searchTerm = ref('')
const selectedMatch = ref(null)
const password = ref('')
const invalidPass = ref(false)

const filteredMatches = computed(() =>
  (props.payload.matches || []).filter(match =>
    match.mapLabel.toLowerCase().includes(searchTerm.value.toLowerCase()) ||
    match.creator.toLowerCase().includes(searchTerm.value.toLowerCase())
  )
)

function handleJoin(match) {
  if (match.members >= match.maxMembers) return
  if (match.password && match.password?.length > 0) {
    selectedMatch.value = match
  } else {
    onJoinMatch(match.matchId, match.map,null,null,match.bucketId)
  }
}

function handlePasswordSubmit() {
  if (selectedMatch.value && password.value) {
    onJoinMatch(selectedMatch.value.matchId,selectedMatch.value.map, selectedMatch.value.password, password.value)
  }
}

function onJoinMatch(matchId,map,matchPass,pass,bucketId) {
  if(props.payload.mode==='tdm'){
    if(pass?.length>0){
      if(pass===matchPass){
        joinTDM(matchId,map)
      } else {
        notificationStore.show('error', 'Invalid Password');
        invalidPass.value = true
      }
    }else{
      joinTDM(matchId,map)
    }
  }else{
    // DM mode - validate password if provided
    if(pass?.length>0){
      if(pass===matchPass){
        joinDM(matchId, map, bucketId)
      } else {
        notificationStore.show('error', 'Invalid Password');
        invalidPass.value = true
        return
      }
    }else{
      joinDM(matchId, map, bucketId)
    }
  }
}

function joinDM(matchId, map, bucketId) {
  fetch(`https://i-tdm/join-dm`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      map: map,
      matchId: matchId,
      bucketId: bucketId
    })
  })
  selectedMatch.value = null
  password.value = ''
  emit('close')
}

function joinTDM(matchId,map) {
  fetch(`https://${GetParentResourceName()}/join-tdm-lobby`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      matchId,
      map:map
    })
  })
}
</script>

<template>
  <div class="page">
    <div class="content-atdm">

      <!-- HEADER -->
      <div class="header">
        <button class="back" @click="emit('change','join')">
          <ArrowLeft size="20" />
          Back
        </button>

        <h2>
          {{ payload.mode === 'tdm'
            ? 'Join Team Deathmatch'
            : 'Join Deathmatch' }}
        </h2>

        <div class="spacer"></div>
      </div>

      <!-- SEARCH -->
      <div class="search">
        <Search class="search-icon" />
        <input
          class="input-atdm"
          placeholder="Search by map or creator..."
          v-model="searchTerm"
        />
      </div>

      <!-- MATCH LIST -->
      <div class="match-list scrollable">
        <div
          v-for="match in filteredMatches"
          :key="match.matchId"
          class="match-card"
          :class="{ full: match.members >= match.maxMembers }"
        >
          <img
            :src="`assets/maps/${match.image}`"
            :alt="match.mapLabel"
            class="map-image"
          />

          <div class="info">
            <div>
              <span class="atdm-grey-text">Map</span>
              <p>{{ match.mapLabel }}</p>
            </div>

            <div>
              <span class="atdm-grey-text">Creator</span>
              <p>{{ match.creator }}</p>
            </div>

            <div>
              <span class="atdm-grey-text">Players</span>
              <p>
                <Users size="14" />
                {{ match.members }}/{{ match.maxMembers }}
              </p>
            </div>

            <div v-if="payload.mode === 'tdm'">
              <span class="atdm-grey-text">Weapon</span>
              <p>
                <Shield size="14" />
                {{ match.weapon }}
              </p>
            </div>
          </div>

          <div class="actions">
            <Lock
              v-if="match.password && match.password.length > 0"
              class="lock"
            />

            <button
              :disabled="match.members >= match.maxMembers"
              @click="handleJoin(match)"
            >
              {{ match.members >= match.maxMembers ? 'Full' : 'Join' }}
            </button>
          </div>
        </div>

        <div v-if="filteredMatches.length === 0" class="empty">
          No active matches found
        </div>
      </div>
    </div>

    <!-- PASSWORD MODAL -->
    <div v-if="selectedMatch" class="modal" @click="selectedMatch = null; invalidPass=false">
      <div class="modal-box" @click.stop>
        <h3>
          <Lock />
          Password Required
        </h3>

        <p>This match is private. Enter the password to join.</p>

        <input
          class="input"
          type="password"
          placeholder="Enter password"
          v-model="password"
          @keyup.enter="handlePasswordSubmit; invalidPass=false"
          autofocus
        />

        <div class="modal-actions">
          <button
            class="cancel"
            @click="selectedMatch = null; password = '';invalidPass=false"
          >
            Cancel
          </button>

          <button
            class="confirm"
            :disabled="!password"
            @click="handlePasswordSubmit"
          >
            Join
          </button>
        </div>
      </div>
    </div>

  </div>
</template>

<style scoped>
/* === SAME CSS, UNCHANGED === */

.page {
  min-height: 100vh;
  background: radial-gradient(circle at top, #111, #000);
  color: white;
}

.content-atdm {
  max-width: 1200px;
  margin: auto;
  padding: 32px;
}

.header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 24px;
}

.back {
  background: none;
  border: none;
  color: #ccc;
  display: flex;
  gap: 8px;
  cursor: pointer;
  justify-content: center;
  align-items: center;
}

.spacer {
  width: 80px;
}

.search {
  position: relative;
  margin-bottom: 24px;
}

.search-icon {
  position: absolute;
  left: 12px;
  top: 50%;
  transform: translateY(-50%);
  opacity: 0.5;
}

.atdm-grey-text {
  color: rgba(255, 255, 255, 0.6);
  font-size: 0.875rem; 
  margin-bottom: 0.25rem;
}

.input-atdm {
  width: 95%;
  padding: 10px 12px 10px 36px;
  background: rgba(0, 0, 0, 0.6);
  border: 1px solid #444;
  border-radius: 6px;
  color: white;
}

.match-card {
  display: flex;
  gap: 16px;
  padding: 16px;
  margin-bottom: 12px;
  border: 2px solid #333;
  border-radius: 8px;
  background: rgba(0, 0, 0, 0.6);
}

.match-card.full {
  opacity: 0.6;
  border-color: #552222;
}

.map-image {
  width: 130px;
  height: 80px;
  object-fit: cover;
  border-radius: 4px;
}

.info {
  flex: 1;
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(120px, 1fr));
  gap: 12px;
}

.actions {
  display: flex;
  align-items: center;
  gap: 12px;
}

.actions button {
  padding: 8px 16px;
  background: #22c55e;
  border: none;
  border-radius: 4px;
  color: white;
}

.actions button:disabled {
  background: #555;
  cursor: not-allowed;
}

.lock {
  color: orange;
}

.empty {
  text-align: center;
  padding: 32px;
  opacity: 0.6;
}

.modal {
  position: fixed;
  inset: 0;
  background: rgba(0, 0, 0, 0.85);
  display: flex;
  align-items: center;
  justify-content: center;
}

.modal-box {
  background: #111;
  border: 2px solid orange;
  border-radius: 8px;
  padding: 24px;
  width: 100%;
  max-width: 400px;
}

.modal-box .input {
  width: 80%;
  padding: 12px 14px;
  background: #0b0b0b;
  border: 1px solid #2a2a2a;
  border-radius: 6px;
  color: white;
  font-size: 14px;
  outline: none;
}

.modal-box .input::placeholder {
  color: #666;
}

.modal-box .input:focus {
  border-color: #f59e0b;
  box-shadow: 0 0 0 1px rgba(245, 158, 11, 0.4);
}

/* ===== MODAL BUTTONS ===== */
.modal-actions {
  display: flex;
  justify-content: flex-start;
  gap: 8px;
  margin-top: 14px;
}

.modal-actions button {
  height: 32px;
  padding: 0 14px;
  font-size: 13px;
  border-radius: 4px;
  cursor: pointer;
}

/* Cancel */
.modal-actions .cancel {
  background: #f3f3f3;
  color: #111;
  border: none;
}

/* Join */
.modal-actions .confirm {
  background: #3a3a3a;
  color: #999;
  border: none;
}

.modal-actions .confirm:not(:disabled) {
  background: #f59e0b;
  color: #111;
}

.modal-actions .confirm:disabled {
  cursor: not-allowed;
  opacity: 0.6;
}

.scrollable {
  max-height: 500px;
  overflow-y: auto;
  padding-right: 6px;
}

.scrollable::-webkit-scrollbar {
  width: 6px;
}

.scrollable::-webkit-scrollbar-thumb {
  background: #ffffff;
  border-radius: 4px;
}

.scrollable::-webkit-scrollbar-track {
  background: transparent;
}

</style>
