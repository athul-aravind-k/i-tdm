<script setup>
import { computed } from 'vue'

/* =========================
   Props / Emits
========================= */
const props = defineProps({
  payload: {
    type: Array,
    required: true
  }
})

const emit = defineEmits(['change'])

/* =========================
   FiveM-safe helper
========================= */
function getResourceName() {
  return window.GetParentResourceName
    ? GetParentResourceName()
    : 'dev'
}

/* =========================
   Time formatting
========================= */
function formatTime(ms) {
  if (ms <= 0) return '00 : 00'

  const minutes = Math.floor((ms % (1000 * 60 * 60)) / (1000 * 60))
  const seconds = Math.floor((ms % (1000 * 60)) / 1000)

  return `${minutes} : ${seconds < 10 ? '0' : ''}${seconds}`
}

/* =========================
   Matches with computed time
========================= */
const matchesWithTime = computed(() => {
  const now = Date.now()

  return props.payload.map(match => {
    const endTime = now + match.timeLeft
    return {
      ...match,
      timeFormatted: formatTime(endTime - Date.now()),
      memberCount: `${match.members}/${match.maxMembers}`,
      creatorShort: match.creator.substring(0, 12)
    }
  })
})

/* =========================
   Join match
========================= */
function joinMatch(match) {
  emit('change', 'main')

  fetch(`https://${getResourceName()}/join-dm`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      map: match.map,
      matchId: String(match.matchId),
      bucketId: match.bucketId
    })
  })
}
</script>

<template>
  <div class="create-container">
    <!-- Back -->
    <h2 class="close" @click="emit('change','join')">
      &lt; Back
    </h2>

    <h2 class="title-text">
      Active lobbies
    </h2>

    <!-- MATCH LIST -->
    <div v-if="matchesWithTime.length" class="match-container">
      <div
        v-for="match in matchesWithTime"
        :key="match.matchId"
        class="match"
      >
        <div class="match-items">
          <div class="match-contents">
            <img src="/assets/loc-pin.svg" />
            <span class="match-map match-text">
              {{ match.mapLabel }}
            </span>
          </div>

          <div class="match-contents">
            <img src="/assets/crown.svg" />
            <span class="creator-name match-text">
              {{ match.creatorShort }}
            </span>
          </div>

          <div class="match-contents">
            <img src="/assets/clock-match.svg" />
            <span class="match-time match-text">
              {{ match.timeFormatted }}
            </span>
          </div>

          <div class="match-contents">
            <img src="/assets/members.svg" />
            <span class="match-members match-text">
              {{ match.memberCount }}
            </span>
          </div>

          <div class="match-contents match-btn-container">
            <button
              class="match-select-btn"
              @click="joinMatch(match)"
            >
              Join
            </button>
          </div>
        </div>
      </div>
    </div>

    <!-- NO MATCHES -->
    <div v-else class="no-match">
      No Active Matches Found
    </div>
  </div>
</template>
