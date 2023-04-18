var isCreator = false;
var selectedMap = null;

$(function () {
  window.addEventListener("message", function (event) {
    if (event.data.type == "open-ui") {
      openUi(true);
    }
    if (event.data.type == "kill-msg") {
      showKillToast(event.data.message);
    }
    if (event.data.type == "update-stats") {
      updateHud(event.data.message);
    }
    if (event.data.type == "toggle-hud") {
      const data = event.data.message;
      toggleHud(data.bool, data.time);
    }
  });
});

function openUi(bool) {
  if (bool) {
    $(".popup").css("display", "block");
    $(".card-container").css("display", "flex");
    setTimeout(function () {
      $(".popup").css("opacity", 1);
    }, 100);
    $("body").css("background-color", "rgba(0, 0, 0, 0.61)");
  } else {
    $(".create-container").empty();
    $(".card-container").css("display", "none");
    $(".popup").css("display", "none");
    $(".create-container").css("display", "none");
    $("body").css("background-color", "rgba(0, 0, 0, 0)");
    setTimeout(function () {
      $(".popup").css("opacity", 0);
    }, 100);
    $.post("https://i-tdm/close");
  }
  selectedMap = null;
}

function setupCreateMatchScreen(maps, isTdm) {
  if (isTdm) {
    console.log("TDM");
  } else {
    showMaps(maps);
  }
}

$(document).on("click", "#create-btn", function (e) {
  showCreateOptions();
});

$(document).on("click", "#join-btn", function (e) {
  showJoinOptions();
});

$(document).on("click", "#leader-board-btn", function (e) {
  //click leaderboard
});

$(document).on("click", "#back-btn-mode", function (e) {
  $(".create-container").css("display", "none");
  $(".card-container").css("display", "flex");
  isCreator = false;
});

$(document).on("click", "#back-btn-join", function (e) {
  $(".create-container").css("display", "none");
  $(".create-container").empty();
  $(".card-container").css("display", "flex");
});

$(document).on("click", "#join-dm", function (e) {
  // show active matches
  //change hardcode
  openUi(false);

  $.post(
    "https://i-tdm/join-dm",
    JSON.stringify({ map: "map2", matchId: 1, bucketId: 2 }),
    function (data) {
      if (data) {
        // load hud here
      }
    }
  );
});

$(document).on("click", "#join-tdm", function (e) {
  // show TDM maps
  //change hardcode
  $.post(
    "https://i-tdm/join-tdm",
    JSON.stringify({ map: "map1" }),
    function (data) {
      // load hud here
    }
  );
});

$(document).on("click", "#create-dm", function (e) {
  $.post(
    "https://i-tdm/get-maps",
    JSON.stringify({ isTdm: false }),
    function (data) {
      setupCreateMatchScreen(data, false);
    }
  );
});

$(document).on("click", "#create-tdm", function (e) {
  $.post(
    "https://i-tdm/get-maps",
    JSON.stringify({ isTdm: true }),
    function (data) {
      // setupCreateMatchScreen(data.maps, true);
    }
  );
});

$(document).on("keydown", function () {
  if (event.keyCode == 27) {
    //esc button
    openUi(false);
  }
});

$(document).on("click", ".map-name-container", function (e) {
  $(".map-name-container").removeClass("map-name-container-selected");
  $(this).addClass("map-name-container-selected");
  var map = $(this).attr("data-name");
  selectedMap = map;
});

$(document).on("click", "#back-btn-select-map", function (e) {
  $(".create-container").empty();
  showCreateOptions();
});

$(document).on("click", "#confirm-dm-selection", function (e) {
  $.post(
    "https://i-tdm/startDeathMatch",
    JSON.stringify({ selectedMap }),
    function (data) {
      openUi(false);
    }
  );
});

var messageQueue = []; // Array to hold queued messages

function showToast(killer, victim, type) {
  var container = document.getElementById("toast-container");
  var toast = document.createElement("div");
  toast.classList.add("toast");
  if (type == "killed") {
    toast.classList.add("toast-kill");
  } else if (type == "dead") {
    toast.classList.add("toast-killed");
  } else if (type == "other") {
    toast.classList.add("toast-other");
  }
  message = `<span class="killer-name"> ${killer + "  "}</span>
  <img class="bullet-msg" src="assets/bullet.png" />
  <span class="victim-name">${"  " + victim}</span>`;
  toast.innerHTML = message;

  if (container.childElementCount >= 3) {
    messageQueue.push(message); // Queue the message if container is full
  } else {
    container.appendChild(toast);
    var timeout = setTimeout(function () {
      container.removeChild(toast);
      if (messageQueue.length > 0) {
        showToast(messageQueue.shift()); // Display queued message if available
      }
    }, 3000);
    toast.timeout = timeout; // Store a reference to the timeout on the toast element
  }
  return toast; // Return the toast element for reference
}

var showButton = document.getElementById("show-toast-button");
var toasts = []; // Array to hold references to the toast elements

function showKillToast(data) {
  const killer = data.killer;
  const killed = data.killed;
  const type = data.type;
  var toast = showToast(killer, killed, type);
  toasts.push(toast);

  // Remove the first toast element after 5 seconds
  setTimeout(function () {
    var removedToast = toasts.shift();
    if (removedToast.parentNode) {
      removedToast.parentNode.removeChild(removedToast);
    }
    if (messageQueue.length > 0) {
      showToast(messageQueue.shift()); // Display queued message if available
    }
  }, 5000);
}

function toggleHud(bool, time) {
  if (bool) {
    $(".progress-bars").css("display", "flex");
    $(".kd-numbers").css("display", "block");
    toggleTimer(true, time);
    $(".timer-container").css("display", "flex");
  } else {
    $(".progress-bars").css("display", "none");
    $(".kd-numbers").css("display", "none");
    $(".timer-container").css("display", "none");
    toggleTimer(false, 0);
  }
}

function updateHud(data) {
  const hpPer = (data.hp / 200) * 100;
  const armor = data.armor;

  if (hpPer <= 10) {
    $("#health-bar").removeClass("health-orange");
    $("#health-bar").removeClass("health-yellow");
    $("#health-bar").removeClass("health-light-yellow");
    $("#health-bar").removeClass("health-green");
    $("#health-bar").addClass("health-red");
  } else if (hpPer <= 25) {
    $("#health-bar").removeClass("health-red");
    $("#health-bar").removeClass("health-yellow");
    $("#health-bar").removeClass("health-light-yellow");
    $("#health-bar").removeClass("health-green");
    $("#health-bar").addClass("health-orange");
  } else if (hpPer <= 50) {
    $("#health-bar").removeClass("health-red");
    $("#health-bar").removeClass("health-light-yellow");
    $("#health-bar").removeClass("health-green");
    $("#health-bar").removeClass("health-orange");
    $("#health-bar").addClass("health-yellow");
  } else if (hpPer <= 75) {
    $("#health-bar").removeClass("health-red");
    $("#health-bar").removeClass("health-green");
    $("#health-bar").removeClass("health-orange");
    $("#health-bar").removeClass("health-yellow");
    $("#health-bar").addClass("health-light-yellow");
  } else {
    $("#health-bar").removeClass("health-red");
    $("#health-bar").removeClass("health-orange");
    $("#health-bar").removeClass("health-yellow");
    $("#health-bar").removeClass("health-light-yellow");
    $("#health-bar").addClass("health-green");
  }

  $(".armor-progress").css("width", armor + "%");
  $(".health-progress").css("width", hpPer + "%");
  $("#health-count").html(
    `<img class="stats-img" src="assets/hp.png" alt=""> ${hpPer}`
  );
  $("#armor-count").html(
    `<img class="stats-img" src="assets/armor.png" alt=""> ${armor}`
  );
  $("#clip-ammo").html(data.clip);
  $("#total-ammo").html(data.ammo);
  $("#death-count").html(data.deaths);
  $("#kill-count").html(data.kills);
}

function toggleTimer(bool, time) {
  var x;
  if (bool) {
    $(".timer-container").css("display", "flex");
    var timer = new Date().getTime() + time;
    function updateTimer() {
      var now = new Date().getTime();
      var t = timer - now;
      var minutes = Math.floor((t % (1000 * 60 * 60)) / (1000 * 60));
      var seconds = Math.floor((t % (1000 * 60)) / 1000);
      const timeMsg = minutes + " : " + (seconds < 10 ? "0" : "") + seconds;
      $("#timer").html(timeMsg);
      if (t <= 60000) {
        $("#timer").css("color", "red");
      }
      if (t <= 0) {
        clearInterval(x);
        $("#timer").html("00 : 00");
        $("#timer").css("color", "white");
      } else {
        x = setTimeout(updateTimer, 1000);
      }
    }
    updateTimer();
  } else {
    $(".timer-container").css("display", "none");
    $("#timer").html("00 : 00");
    $("#timer").css("color", "white");
    clearTimeout(x);
  }
}

function showMaps(maps) {
  var container = `<h2 class="title-text">Create a lobby</h2>
  <h2 id="back-btn-select-map" class="close"> < Back</h2>
  <div class="map-container">`;
  if (maps.length) {
    for (i = 0; i <= maps.length - 1; i++) {
      var map = `<div class="map" style="background-image: url(assets/maps/${maps[i].image});">
      <div class="map-name-container" data-name="${maps[i].name}"><span>${maps[i].label}</span></div>
    </div>`;
      container += map;
    }
  }
  container += `<button id="confirm-dm-selection" class="confirm-dmatch-btn">Confirm</button></div>`;
  $(".create-container").empty();
  $(".create-container").append(container);
  $(".create-container").css("display", "flex");
  $(".card-container").css("display", "none");
}

function showCreateOptions() {
  var cardsHTML = `
  <h2 id="back-btn-join" class="close">< Back</h2>
    <div class="card tdm-card">
      <h2 class="card-title">Team Death Match</h2>
      <button id="create-tdm" class="card-btn tdm-button">Select</button>
      <img class="card-bottom-image create-card-image" src="assets/teamdeathmatch.png" alt="" />
    </div>
    <div class="card death-card">
      <h2 class="card-title">Death Match</h2>
      <button id="create-dm" class="card-btn dm-button">Select</button>
      <img class="card-bottom-image join-card-image" src="assets/deathmatch-card.png" alt="" />
    </div>
    <div class="card coming-soon-card">
      <h2 class="coming-soon">coming soon..</h2>
    </div>
  `;
  $(".create-container").append(cardsHTML);
  $(".create-container").css("display", "flex");
  $(".card-container").css("display", "none");
  isCreator = true;
}

function showJoinOptions() {
  var cardsHTML = `
  <h2 id="back-btn-join" class="close">< Back</h2>
    <div class="card tdm-card">
      <h2 class="card-title">Team Death Match</h2>
      <button id="join-tdm" class="card-btn tdm-button">Select</button>
      <img class="card-bottom-image create-card-image" src="assets/teamdeathmatch.png" alt="" />
    </div>
    <div class="card death-card">
      <h2 class="card-title">Death Match</h2>
      <button id="join-dm" class="card-btn dm-button">Select</button>
      <img class="card-bottom-image join-card-image" src="assets/deathmatch-card.png" alt="" />
    </div>
    <div class="card coming-soon-card">
      <h2 class="coming-soon">coming soon..</h2>
    </div>
  `;
  $(".create-container").append(cardsHTML);
  $(".create-container").css("display", "flex");
  $(".card-container").css("display", "none");
}
