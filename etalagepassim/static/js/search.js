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
    function createAutocompleter($input) {
        var territoriaQuery = etalagepassim.search.autocompleterUrl  + '?jsonp=?&' + $.param({
            parent: etalagepassim.search.base_territory,
            kind: etalagepassim.search.kinds || ''
            }, true);
        $input.typeahead([
            {
                header: '<h5 class="autocompleter-header">Territories</h5>',
                remote: {
                    dataType: 'jsonp',
                    filter: function(json) {
                        return json.data.items;
                    },
                    url: territoriaQuery + '&term=%QUERY'
                },
                prefetch: territoriaQuery,
                valueKey: 'main_postal_distribution'
            },
            {
                header: '<h5 class="autocompleter-header">Categories</h5>',
                remote: {
                    filter: function(json) {
                        return json.data.items;
                    },
                    url: '/api/v1/categories/autocomplete?term=%QUERY'
                },
                prefetch: '/api/v1/categories/autocomplete?term=a',
                valueKey: 'tag'
            }
        ]);
    }

    return {
        createAutocompleter: createAutocompleter
    };
})(jQuery);


