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


etalagepassim.form = (function ($) {
    function initSearchForm(options) {
        $("a.btn-atom-feed").on("click", function (event) {
            $searchForm = options.searchForm || $(this).closest('form');
            feed_url = $(this).attr("href");
            if (feed_url.search(/\?/) > 0) {
                $(this).attr("href", feed_url.substr(0, feed_url.search(/\?/)) + '?' + $searchForm.serialize());
            }
        });
    }

    function initContactForm(options) {
        $(options.formSelector).submit(function(event) {
            event.preventDefault();
            $.ajax({
                data: $(this).serializeArray(),
                dataType: 'json',
                method: 'get',
                url: '/mail'
            }).done(function(data, textStatus, jqXHR) {
                if (data.errors) {
                    $.each($(options.formSelector).find(':input'), function(i, input) {
                        if (data.errors[input.id]) {
                            $(options.formSelector).find('#input-error-' + input.id).text(data.errors[input.id]);
                        }
                        else {
                            $(options.formSelector).find('#input-error-' + input.id).empty();
                        }
                    });
                    if (data.errors.captcha) {
                        Recaptcha.reload();
                    }
                }
                else {
                    window.location.href = options.callbackUrl;
                }
            }).fail(function(jqXHR, textStatus, errorThrown) {
                alert('Error : Your email has been sent. Please accept our apologies.');
            });
        });
    }

    return {
        initContactForm: initContactForm,
        initSearchForm: initSearchForm
    };
})(jQuery);
