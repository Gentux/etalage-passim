/*
 * Etalage-Passim -- Customization of Etalage for Passim
 * By: Emmanuel Raviart <eraviart@easter-eggs.com>
 *
 * Copyright (C) 2011, 2012, 2013 Easter-eggs
 * http://gitorious.org/passim/etalage-passim
 *
 * This file is part of Etalage-Passim.
 *
 * Etalage-Passim is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License as
 * published by the Free Software Foundation, either version 3 of the
 * License, or (at your option) any later version.
 *
 * Etalage-Passim is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Affero General Public License for more details.
 *
 * You should have received a copy of the GNU Affero General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

var etalagepassim = etalagepassim || {};

// Adjust frame height for 5 seconds.
etalagepassim.adjustFrameHeightCount = 5 * 5;
etalagepassim.frameHeight = null;


function adjustFrameHeight(seconds) {
    var frameNewHeight = $(document.body).height();
    if (seconds) {
        // Adjust frame height for a few seconds ("* 5" is because of 200 ms timeout).
        etalagepassim.adjustFrameHeightCount = seconds * 5;
    }
    if (frameNewHeight != etalagepassim.frameHeight) {
        etalagepassim.rpc.adjustHeight(frameNewHeight);
        etalagepassim.frameHeight = frameNewHeight;
    }
    if (etalagepassim.adjustFrameHeightCount-- >= 0) {
        setTimeout(function() {
            adjustFrameHeight();
        }, 200);
    }
}


function initGadget() {
    adjustFrameHeight();

    $("form.internal").bind("submit", function (event) {
        event.preventDefault();
        passim.rpc.requestNavigateTo($(this).attr("action"), $(this).serializeArray().concat({
            name: "submit",
            value: "Submit"
        }));
    });

    $("a.internal").on("click", function (event) {
        event.preventDefault();
        passim.rpc.requestNavigateTo($(this).attr("href"));
    });

    $("a[href][rel=bookmark]").attr("target", "_blank");
    $("a[href][rel=mobile]").attr("target", "_blank");
    $("a[href][rel=external]").attr("target", "_blank");
}
