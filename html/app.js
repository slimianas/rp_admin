let isOpen = false;
let selectedPlayer = null;


/* =========================================
   NUI MESSAGES
========================================= */

window.addEventListener('message', function (event) {

    const data = event.data;

    /* OPEN */

    if (data.action === 'open') {

        isOpen = true;

        document.body.style.display = 'block';

const panel = document.getElementById('admin-panel');

if (panel) {
    panel.style.display = 'flex';
}

        requestPlayers();
    }


    /* CLOSE */

    if (data.action === 'close') {

        isOpen = false;

        closePlayerModal();

        document.body.style.display = 'none';

        const panel = document.getElementById('admin-panel');

if (panel) {
    panel.style.display = 'none';
}

    }


    /* UPDATE PLAYERS */

    if (data.action === 'updatePlayers') {

        updatePlayers(data.players || []);
    }


    /* ACTION RESULT */

    if (data.action === 'actionResult') {

        console.log(
            '[RP_ADMIN]',
            data.success ? 'SUCCESS:' : 'ERROR:',
            data.message
        );
    }

        /* SERVER ANNOUNCEMENT */

    if (data.action === 'announcement') {

        showAnnouncement(data.message || '');

    }

});


/* =========================================
   REQUEST PLAYERS
========================================= */

function requestPlayers() {

    fetch(
        `https://${GetParentResourceName()}/requestPlayers`,
        {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({})
        }
    ).catch(function () {});
}


/* =========================================
   UPDATE PLAYERS
========================================= */

function updatePlayers(players) {

    const playerList =
        document.querySelector('.player-list');

    if (!playerList) {
        return;
    }


    /* ONLINE COUNT */

    const statValues =
        document.querySelectorAll('.stat-value');

    if (statValues.length > 0) {
        statValues[0].textContent = players.length;
    }


    /* SIDEBAR COUNT */

    const navCount =
        document.querySelector('.nav-count');

    if (navCount) {
        navCount.textContent = players.length;
    }


    /* CLEAR OLD PLAYERS */

    playerList.innerHTML = '';


    /* NO PLAYERS */

    if (players.length === 0) {

        playerList.innerHTML = `
            <div class="player-row">

                <div class="player-details">

                    <strong>No players online</strong>

                    <span>
                        Waiting for players...
                    </span>

                </div>

            </div>
        `;

        return;
    }


    /* CREATE PLAYERS */

    players.forEach(function (player) {

        const row =
            document.createElement('div');

        row.className = 'player-row';


        const initial =
            player.name &&
            player.name.length > 0
                ? player.name.charAt(0).toUpperCase()
                : '?';


        let pingColor = '#43d58c';

        if (player.ping > 100) {
            pingColor = '#ffa24e';
        }

        if (player.ping > 200) {
            pingColor = '#ff6262';
        }


        row.innerHTML = `
            <div class="player-avatar">
                ${escapeHtml(initial)}
            </div>

            <div class="player-details">

                <strong>
                    ${escapeHtml(player.name)}
                </strong>

                <span>
                    ID: ${player.id}
                    ·
                    ${escapeHtml(player.job)}
                </span>

            </div>

            <div class="player-ping">

                <span
                    class="ping-dot"
                    style="background:${pingColor};"
                ></span>

                ${player.ping} ms

            </div>

            <button
                class="player-more"
                data-player-id="${player.id}"
            >
                •••
            </button>
        `;


        playerList.appendChild(row);
    });


    /* CONNECT PLAYER BUTTONS */

    const playerButtons =
        document.querySelectorAll('.player-more');


    playerButtons.forEach(function (button) {

        button.addEventListener(
            'click',
            function () {

                const playerId =
                    Number(button.dataset.playerId);


                const player =
                    players.find(function (p) {

                        return p.id === playerId;

                    });


                if (player) {
                    openPlayerModal(player);
                }

            }
        );

    });

}


/* =========================================
   OPEN PLAYER MODAL
========================================= */

function openPlayerModal(player) {

    selectedPlayer = player;


    const modal =
        document.getElementById('player-modal');

    if (!modal) {
        return;
    }


    const initial =
        player.name &&
        player.name.length > 0
            ? player.name.charAt(0).toUpperCase()
            : '?';


    const avatar =
        document.getElementById('modal-avatar');

    const name =
        document.getElementById('modal-player-name');

    const id =
        document.getElementById('modal-player-id');

    const job =
        document.getElementById('modal-player-job');

    const ping =
        document.getElementById('modal-player-ping');


    if (avatar) {
        avatar.textContent = initial;
    }

    if (name) {
        name.textContent = player.name;
    }

    if (id) {
        id.textContent = player.id;
    }

    if (job) {
        job.textContent = player.job;
    }

    if (ping) {
        ping.textContent = player.ping + ' ms';
    }


    modal.classList.add('visible');
}


/* =========================================
   CLOSE PLAYER MODAL
========================================= */

function closePlayerModal() {

    const modal =
        document.getElementById('player-modal');

    if (!modal) {
        return;
    }

    modal.classList.remove('visible');

    selectedPlayer = null;
}


/* =========================================
   PLAYER ACTION
========================================= */

function performPlayerAction(action) {

    if (!selectedPlayer) {
        return;
    }


    const playerId =
        Number(selectedPlayer.id);


    fetch(
        `https://${GetParentResourceName()}/playerAction`,
        {
            method: 'POST',

            headers: {
                'Content-Type': 'application/json'
            },

            body: JSON.stringify({
                action: action,
                playerId: playerId
            })
        }
    ).catch(function () {});


    if (
        action === 'kick' ||
        action === 'teleport'
    ) {

        closePlayerModal();
    }
}


/* =========================================
   ACTION BUTTONS
========================================= */

document.addEventListener(
    'click',
    function (event) {

        const actionButton =
            event.target.closest('[data-action]');


        if (!actionButton) {
            return;
        }


        if (!selectedPlayer) {
            return;
        }


        const action =
            actionButton.dataset.action;


        performPlayerAction(action);

    }
);


/* =========================================
   MODAL CLOSE
========================================= */

const modalClose =
    document.getElementById('modal-close');

if (modalClose) {

    modalClose.addEventListener(
        'click',
        function () {

            closePlayerModal();

        }
    );

}


const modalCancel =
    document.getElementById('modal-cancel');

if (modalCancel) {

    modalCancel.addEventListener(
        'click',
        function () {

            closePlayerModal();

        }
    );

}


/* =========================================
   ESCAPE
========================================= */

document.addEventListener(
    'keydown',
    function (event) {

        if (event.key !== 'Escape') {
            return;
        }


        /* Close modal first */

        const modal =
            document.getElementById('player-modal');


        if (
            modal &&
            modal.classList.contains('visible')
        ) {

            closePlayerModal();

            return;
        }


        /* Close admin panel */

        if (!isOpen) {
            return;
        }


        fetch(
            `https://${GetParentResourceName()}/close`,
            {
                method: 'POST',

                headers: {
                    'Content-Type':
                        'application/json'
                },

                body: JSON.stringify({})
            }
        );

    }
);

/* =========================================
   VEHICLE MODAL
========================================= */

const vehicleModal =
    document.getElementById('vehicle-modal');

const vehicleClose =
    document.getElementById('vehicle-close');

const vehicleCancel =
    document.getElementById('vehicle-cancel');


function openVehicleModal() {

    if (!vehicleModal) {
        return;
    }

    vehicleModal.classList.add('visible');
}


function closeVehicleModal() {

    if (!vehicleModal) {
        return;
    }

    vehicleModal.classList.remove('visible');
}


/* SIDEBAR VEHICLES */

const navItems =
    document.querySelectorAll('.nav-item');


navItems.forEach(function (item) {

    const text =
        item.textContent.trim();


    if (text.includes('Vehicles')) {

        item.addEventListener(
            'click',
            function () {

                openVehicleModal();

            }
        );

    }

});


/* QUICK ACTION VEHICLE BUTTON */

const vehicleActions =
    document.querySelectorAll('.action');


vehicleActions.forEach(function (button) {

    if (
        button.textContent
            .toLowerCase()
            .includes('vehicle management')
    ) {

        button.addEventListener(
            'click',
            function () {

                openVehicleModal();

            }
        );

    }

});


/* CLOSE */

if (vehicleClose) {

    vehicleClose.addEventListener(
        'click',
        closeVehicleModal
    );

}

if (vehicleCancel) {

    vehicleCancel.addEventListener(
        'click',
        closeVehicleModal
    );

}


/* =========================================
   SPAWN VEHICLE
========================================= */

const spawnVehicleButton =
    document.getElementById('spawn-vehicle');


const vehicleInput =
    document.getElementById('vehicle-model');


if (spawnVehicleButton) {

    spawnVehicleButton.addEventListener(
        'click',
        function () {

            const model =
                vehicleInput.value.trim();


            if (!model) {
                return;
            }


            fetch(
                `https://${GetParentResourceName()}/vehicleAction`,
                {
                    method: 'POST',

                    headers: {
                        'Content-Type':
                            'application/json'
                    },

                    body: JSON.stringify({
                        action: 'spawn',
                        model: model
                    })
                }
            ).catch(function () {});


            vehicleInput.value = '';

        }
    );

}


/* ENTER TO SPAWN */

if (vehicleInput) {

    vehicleInput.addEventListener(
        'keydown',
        function (event) {

            if (event.key === 'Enter') {

                spawnVehicleButton.click();

            }

        }
    );

}


/* =========================================
   CURRENT VEHICLE ACTIONS
========================================= */

document.addEventListener(
    'click',
    function (event) {

        const button =
            event.target.closest(
                '[data-vehicle-action]'
            );


        if (!button) {
            return;
        }


        const action =
            button.dataset.vehicleAction;


        fetch(
            `https://${GetParentResourceName()}/vehicleAction`,
            {
                method: 'POST',

                headers: {
                    'Content-Type':
                        'application/json'
                },

                body: JSON.stringify({
                    action: action
                })
            }
        ).catch(function () {});

    }
);

/* =========================
   SERVER MANAGEMENT
   ========================= */

const serverModal = document.getElementById('server-modal');

function openServerModal() {
    if (!serverModal) return;

    serverModal.classList.add('visible');

    const playerCount = document.querySelector('.stat-value');

    if (playerCount) {
        const serverCount = document.getElementById('server-player-count');

        if (serverCount) {
            serverCount.textContent = playerCount.textContent;
        }
    }
}

function closeServerModal() {
    if (!serverModal) return;

    serverModal.classList.remove('visible');
}


/* Open from sidebar */

document.querySelectorAll('.nav-item').forEach(function (item) {
    const text = item.textContent.trim().toLowerCase();

    if (text.includes('server')) {
        item.addEventListener('click', function () {
            openServerModal();
        });
    }
});


/* Close buttons */

const serverClose = document.getElementById('server-close');

if (serverClose) {
    serverClose.addEventListener('click', function () {
        closeServerModal();
    });
}


const serverCancel = document.getElementById('server-cancel');

if (serverCancel) {
    serverCancel.addEventListener('click', function () {
        closeServerModal();
    });
}


/* =========================
   SERVER ACTIONS
   ========================= */

document.querySelectorAll('[data-server-action]').forEach(function (button) {

    button.addEventListener('click', function () {

        const action = button.dataset.serverAction;

        /*
         * Announcement has its own modal and handler.
         * Do not send it here.
         */
        if (action === 'announcement') {
            return;
        }

        console.log('[RP_ADMIN] Server action:', action);

        fetch(`https://${GetParentResourceName()}/serverAction`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({
                action: action
            })
        }).catch(function () {});

    });

});

/* =========================
   ANNOUNCEMENT
   ========================= */

const announcementModal = document.getElementById('announcement-modal');
const announcementInput = document.getElementById('announcement-message');
const announcementCount = document.getElementById('announcement-count');

function openAnnouncementModal() {
    if (!announcementModal) return;

    announcementModal.classList.add('visible');

    if (announcementInput) {
        announcementInput.focus();
    }
}

function closeAnnouncementModal() {
    if (!announcementModal) return;

    announcementModal.classList.remove('visible');

    if (announcementInput) {
        announcementInput.value = '';
    }

    if (announcementCount) {
        announcementCount.textContent = '0';
    }
}


/* Announcement button */

document.querySelectorAll('[data-server-action="announcement"]').forEach(function (button) {

    button.addEventListener('click', function () {
        openAnnouncementModal();
    });

});


/* Character counter */

if (announcementInput) {

    announcementInput.addEventListener('input', function () {

        if (announcementCount) {
            announcementCount.textContent =
                announcementInput.value.length;
        }

    });

}


/* Close */

const announcementClose =
    document.getElementById('announcement-close');

if (announcementClose) {

    announcementClose.addEventListener('click', function () {
        closeAnnouncementModal();
    });

}


const announcementCancel =
    document.getElementById('announcement-cancel');

if (announcementCancel) {

    announcementCancel.addEventListener('click', function () {
        closeAnnouncementModal();
    });

}


/* Send */

const announcementSend =
    document.getElementById('announcement-send');

if (announcementSend) {

    announcementSend.addEventListener('click', function () {

        const message =
            announcementInput ? announcementInput.value.trim() : '';

        if (!message) {
            return;
        }

        fetch(`https://${GetParentResourceName()}/serverAction`, {

            method: 'POST',

            headers: {
                'Content-Type': 'application/json'
            },

            body: JSON.stringify({
                action: 'announcement',
                message: message
            })

        }).catch(function () {});

        closeAnnouncementModal();

    });

}

/* =========================================
   SERVER ANNOUNCEMENT
========================================= */

function showAnnouncement(message) {

    const notification = document.createElement('div');

    notification.className = 'rp-announcement';

    notification.innerHTML = `
        <div class="rp-announcement-icon">
            !
        </div>

        <div class="rp-announcement-content">

            <div class="rp-announcement-title">
                SERVER ANNOUNCEMENT
            </div>

            <div class="rp-announcement-message">
                ${escapeHtml(message)}
            </div>

        </div>

        <div class="rp-announcement-progress"></div>
    `;

    document.body.appendChild(notification);

    /*
     * The admin panel normally makes body hidden
     * when F10 is closed, so temporarily allow the
     * notification to be displayed.
     */

    document.body.style.display = 'block';

    if (!isOpen) {
        const panel = document.getElementById('admin-panel');

        if (panel) {
            panel.style.display = 'none';
        }
    }

    /* Animate in */

    requestAnimationFrame(function () {
        notification.classList.add('show');
    });

    /* Remove after 8 seconds */

    setTimeout(function () {

        notification.classList.remove('show');

        setTimeout(function () {

            notification.remove();

            if (!isOpen) {
                document.body.style.display = 'none';
            }

        }, 350);

    }, 8000);

}


/* =========================================
   ESCAPE HTML
========================================= */

function escapeHtml(value) {

    return String(value)
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#039;');
}