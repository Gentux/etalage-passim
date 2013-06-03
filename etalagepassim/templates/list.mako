## -*- coding: utf-8 -*-


## Etalage-Passim -- Customization of Etalage for Passim
## By: Emmanuel Raviart <eraviart@easter-eggs.com>
##
## Copyright (C) 2011, 2012, 2013 Easter-eggs
## http://gitorious.org/passim/etalage-passim
##
## This file is part of Etalage-Passim.
##
## Etalage-Passim is free software; you can redistribute it and/or modify
## it under the terms of the GNU Affero General Public License as
## published by the Free Software Foundation, either version 3 of the
## License, or (at your option) any later version.
##
## Etalage-Passim is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU Affero General Public License for more details.
##
## You should have received a copy of the GNU Affero General Public License
## along with this program.  If not, see <http://www.gnu.org/licenses/>.


<%!
import markupsafe
from biryani import strings

from etalagepassim import conf, conv, model, ramdb, urls
%>


<%inherit file="/index.mako"/>


<%def name="metas()" filter="trim">
    <%parent:metas/>
    <meta name="robots" content="noindex">
</%def>


<%def name="pagination()" filter="trim">
    % if pager.page_count > 1:
            <div class="pagination pagination-centered">
                <ul>
<%
        url_args = dict(
            (model.Poi.rename_input_to_param(name), value)
            for name, value in inputs.iteritems()
            if name != 'page' and name not in model.Poi.get_visibility_params_names(ctx) and value is not None
            )
%>\
                    <li class="prev${' disabled' if pager.page_number <= 1 else ''}">
                        <a class="internal" href="${urls.get_url(ctx, mode, page = max(pager.page_number - 1, 1),
                                **url_args)}">&larr;</a>
                    </li>
        % for page_number in range(max(pager.page_number - 5, 1), pager.page_number):
                    <li>
                        <a class="internal" href="${urls.get_url(ctx, mode, page = page_number,
                                **url_args)}">${page_number}</a>
                    </li>
        % endfor
                    <li class="active">
                        <a class="internal" href="${urls.get_url(ctx, mode, page = pager.page_number, **url_args
                                )}">${pager.page_number}</a>
                    </li>
        % for page_number in range(pager.page_number + 1, min(pager.page_number + 5, pager.last_page_number) + 1):
                    <li>
                        <a class="internal" href="${urls.get_url(ctx, mode, page = page_number,
                                **url_args)}">${page_number}</a>
                    </li>
        % endfor
                    <li class="next${' disabled' if pager.page_number >= pager.last_page_number else ''}">
                        <a class="internal" href="${urls.get_url(ctx, mode,
                                page = min(pager.page_number + 1, pager.last_page_number), **url_args)}">&rarr;</a>
                    </li>
                </ul>
            </div>
    % endif
</%def>


<%def name="results()" filter="trim">
    % if errors is None:
        % if pager.item_count == 0:
        <div>
            <em>Aucun organisme trouvé.</em>
        </div>
        % else:
        <div>
            Organismes ${pager.first_item_number} à ${pager.last_item_number} sur ${pager.item_count}
        </div>
        <%self:pagination/>
        <%self:results_table/>
        <%self:pagination/>
        % endif
    % endif
</%def>


<%def name="results_table()" filter="trim">
        <table class="table table-bordered table-condensed table-striped">
            <thead>
                <tr>
                    <th>Nom</th>
                    <th>Type de transport</th>
                    <th>Couverture territoriale</th>
                    <th>Territoire couvert</th>
                </tr>
            </thead>
            <tbody>
        % for info_service in pager.items:
                <tr>
                    <td>
                        <a class="internal" href="${urls.get_url(ctx, 'organismes', info_service.slug, info_service._id)}">${info_service.name}</a>
                    </td>
<%
    covered_territories_postal_distribution_str = set()
    transport_offers = None
    for field in info_service.fields:
        field_slug = strings.slugify(field.label)
        if field.id == 'links' and strings.slugify(field.label) == 'offres-de-transport':
            transport_offers = [
                transport_offer
                for transport_offer in (
                    model.Poi.instance_by_id.get(transport_offer_id)
                    for transport_offer_id in field.value
                    )
                if transport_offer is not None
                ] or None if field.value is not None else None
        elif field.id == 'territories' and field_slug == 'territoire-couvert' and field.value is not None:
            for territory_id in field.value:
                territory = ramdb.territory_by_id.get(territory_id)
                if territory is not None:
                    covered_territories_postal_distribution_str.add(territory.main_postal_distribution_str)

    coverages = set()
    transport_types = set()
    use_transport_offers_covered_territories = not covered_territories_postal_distribution_str
    for transport_offer in (transport_offers or []):
        for field in transport_offer.fields:
            field_slug = strings.slugify(field.label)
            if field.id == 'select':
                if field_slug == 'couverture-territoriale' and field.value is not None:
                    coverages.add(field.value)
                elif field_slug == 'type-de-transport' and field.value is not None:
                    transport_types.add(markupsafe.Markup(
                        u'<a href="#" rel="tooltip" title="{0}"><img alt="{0}" src="/passim-images/types-de-transports/{1}.png"></a>'
                        ).format(field.value, strings.slugify(field.value)))
            elif use_transport_offers_covered_territories and field.id == 'territories' \
                    and field_slug == 'territoire-couvert' and field.value is not None:
                for territory_id in field.value:
                    territory = ramdb.territory_by_id.get(territory_id)
                    if territory is not None:
                        covered_territories_postal_distribution_str.add(territory.main_postal_distribution_str)
%>\
                    <td>${markupsafe.escape(u' ').join(sorted(transport_types))}</td>
                    <td>${u', '.join(sorted(coverages))}</td>
                    <td>${u', '.join(sorted(covered_territories_postal_distribution_str))}</td>
                </tr>
        % endfor
            </tbody>
        </table>
</%def>


<%def name="scripts()" filter="trim">
    <%parent:scripts/>
    <script src="${conf['bootstrap.js']}"></script>
    <script>
$(function () {
    $("[rel=tooltip]")
        .tooltip()
        .on('click', function (event) {
            event.preventDefault();
        });
});
    </script>
</%def>


<%def name="title_content()" filter="trim">
${_(u'List')} - ${parent.title_content()}
</%def>

