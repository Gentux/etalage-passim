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


etalagepassim.search = (function ($) {
    function createAutocompleter(options) {
        var options = options || {};
        var territoriaQuery = etalagepassim.search.autocompleterUrl  + '?jsonp=?&' + $.param({
            parent: etalagepassim.search.base_territory,
            kind: etalagepassim.search.kinds || ''
            }, true);
        $(options.inputSelector).typeahead([
            {
                header: '<h5 class="autocompleter-header">' + options.wording.territories + '</h5>',
                remote: {
                    dataType: 'jsonp',
                    filter: function(json) {
                        return json.data.items;
                    },
                    url: territoriaQuery + '&term=%QUERY'
                },
                valueKey: 'main_postal_distribution'
            },
            {
                header: '<h5 class="autocompleter-header">' + options.wording.names + '</h5>',
                remote: {
                    filter: function(json) {
                        return json.data.items;
                    },
                    url: '/api/v1/names/autocomplete?term=%QUERY'
                }
            },
            {
                header: '<h5 class="autocompleter-header">' + options.wording.categories + '</h5>',
                remote: {
                    filter: function(json) {
                        return json.data.items;
                    },
                    url: '/api/v1/categories/autocomplete?term=%QUERY'
                },
                valueKey: 'tag'
            }
        ]);
    }

    function initGeolocation($button) {
        $button.on("click", function() {
            self = $(this);
            if (navigator.geolocation) {
                navigator.geolocation.getCurrentPosition(function(position) {
                    $("#search-form")
                        .append($("<input>", {
                                type: "hidden",
                                name: "geolocation",
                                value: position.coords.latitude + "," + position.coords.longitude
                        })).submit();
                });
            } else {
                self.closest('control-group').addClass('error');
                self.closest('controls').append(
                    $("<span class=\"help-inline\">").text("Geolocation is not supported by this browser.")
                    );
            }
        });
    }

    return {
        createAutocompleter: createAutocompleter,
        initGeolocation: initGeolocation
    };
})(jQuery);


