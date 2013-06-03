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
from etalagepassim import conf, model, urls
%>


<%inherit file="/index.mako"/>


<%def name="css()" filter="trim">
    <%parent:css/>
    <style type="text/css">
textarea {
    width: 100%;
}
    </style>
</%def>


<%def name="gadget()" filter="trim">
<%
    gadget_id = 832 # TODO
    url_args = dict(
        (model.Poi.rename_input_to_param(name), value)
        for name, value in inputs.iteritems()
        if name not in ('container_base_url', 'gadget') and value not in (None, [], '')
        )
    gadget_params = dict(
        path = conf['default_tab'],
        )
    gadget_params.update(url_args)
%>\
<!-- Debut du composant : ${conf['realm']} -->
<div id="gadget-passim" style="height: 3000px"></div>
<script type="text/javascript" src="${conf['gadget-integration.js']}"></script>
<script type="text/javascript">
    comarquage.gadgets.init();
    comarquage.gadgets.renderPassimGadget({
        container: "gadget-passim",
        id: ${gadget_id},
        params: ${gadget_params | n, js},
##        props: {
##            style: {
##                border: '1px solid red'
##            }
##        },
        remote: '${urls.get_full_url(ctx)}'
    });
</script>
<noscript>
    <iframe src="${urls.get_full_url(ctx, 'carte', gadget = gadget_id, **url_args)}" style="height: 3000; width: 100%">
        Votre navigateur ne permet pas d'afficher l'annuaire &agrave; l'int&eacute;rieur de ce site. 
        Cliquez sur <a href="${urls.get_full_url(ctx, 'carte', gadget = gadget_id, **url_args)}">ce lien</a> pour y
        acc&eacute;der.
    </iframe>
</noscript>
<!-- Fin du composant -->
</%def>


<%def name="results()" filter="trim">
        <h2>Installation de l'annuaire sur votre site web</h2>
        <p>
            Cet annuaire vous intéresse ? Vous pouvez l'installer sur votre site web !
        </p>
    % if errors is not None:
        <div class="alert alert-error">
            Vous devez auparavant <strong>corriger les erreurs</strong> dans le formulaire de recherche ci-dessus.
        </div>
    % else:
        <ol>
            <li>Renseignez un territoire et lancez la recherche ci-dessus.</li>
            <li>Copiez le fragment HTML généré ci-dessous et collez-le dans une page web.</li>
        </ol>
<%
        gadget = capture(self.gadget)
%>\
        <textarea readonly rows="${gadget.strip().count(u'\n') + 1}" wrap="off">${gadget}</textarea>
        <div class="form-actions">
            <button class="btn btn-primary" id="select-text-button">Sélectionner le fragment HTML</button>
        </div>
    % endif
</%def>


<%def name="scripts_domready_content()" filter="trim">
    <%parent:scripts_domready_content/>
    $('#select-text-button').click(function () {
        $('textarea').select();
        return false;
    });
</%def>


<%def name="title_content()" filter="trim">
${_(u'Share')} - ${parent.title_content()}
</%def>

