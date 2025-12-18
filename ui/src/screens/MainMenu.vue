<script setup>
/*
  Emits
*/
const emit = defineEmits(['change', 'close'])

/*
  Close UI (Esc text click support if you want later)
*/
function close() {
  emit('close')
}
</script>

<template>
  <div class="card-container">
    <!-- Close Hint -->
    <h2 class="close">
      Press [Esc] to close
    </h2>

    <!-- CREATE CARD -->
    <div class="card create-card">
      <h2 class="card-title">
        want to create a lobby?
      </h2>

      <button
        id="create-btn"
        class="card-btn create-button"
        @click="emit('change', 'create')"
      >
        + Create
      </button>

      <img
        class="card-bottom-image create-card-image"
        src="/assets/create-card.png"
        alt="Create"
      />
    </div>

    <!-- JOIN CARD -->
    <div class="card join-card">
      <h2 class="card-title">
        join an active game
      </h2>

      <button
        id="join-btn"
        class="card-btn join-button"
        @click="emit('change', 'join')"
      >
        Join a game
      </button>

      <img
        class="card-bottom-image join-card-image"
        src="/assets/join-card.png"
        alt="Join"
      />
    </div>

    <!-- LEADERBOARD CARD -->
    <div class="card leader-board">
      <h2 class="card-title">
        view top players here
      </h2>

      <button
        id="leader-board-btn"
        class="card-btn leaderboard-button"
        @click="emit('change', 'leaderboard')"
      >
        LeaderBoard
      </button>

      <img
        class="card-bottom-image leader-card-image"
        src="/assets/leader-card.png"
        alt="Leaderboard"
      />
    </div>
  </div>
</template>
