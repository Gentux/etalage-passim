# -*- coding: utf-8 -*-


# Etalage-Passim -- Customization of Etalage for Passim
# By: Emmanuel Raviart <eraviart@easter-eggs.com>
#
# Copyright (C) 2011, 2012, 2013 Easter-eggs
# http://gitorious.org/passim/etalage-passim
#
# This file is part of Etalage-Passim.
#
# Etalage-Passim is free software; you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# Etalage-Passim is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.


"""Helpers for pagination of sequences"""


from suq import representations

from . import conv


class Pager(representations.UserRepresentable):
    """A representation of one page of items in a larger sequence"""
    first_item_index = None  # index of first item on the current page - starts with 0
    first_item_number = None  # number of first item on the current page - starts with 1 (= first_item_index + 1)
    first_page_number = 1  # number of the first page - starts with 1
    item_count = None  # number of items in the collection
    items = None
    last_item_index = None  # index of last item on the current page
    last_item_number = None  # number of last item on the current page (= last_item_index + 1)
    last_page_number = None  # number of the last page
    page_count = None  # number of pages
    page_max_size = None  # maximal number of items displayed on a page
    page_number = None  # number of the current page
    page_size = None  # number of items displayed on currrent page
    to_json = conv.check(conv.object_to_clean_dict)

    def __init__(self, item_count = None, items = None, page_number = 1, page_max_size = 20):
        """Create a "Pagination" instance.

        item_count
            The total number of items in the collection

        page_number
            The requested page number - starts with 1. Default: 1

        page_max_size
            The maximal number of items to be displayed per page
            Default: 20.
        """
        assert isinstance(item_count, (int, long))
        self.item_count = item_count
        if items is not None:
            self.items = items
        assert isinstance(page_max_size, int)
        self.page_max_size = page_max_size
        assert isinstance(page_number, (int, long))
        self.page_number = page_number

        # Compute the number of the first and last available page.
        if self.item_count > 0:
            self.page_count = ((self.item_count - 1) // self.page_max_size) + 1
            self.last_page_number = self.first_page_number + self.page_count - 1

            # Ensure that the requested page number is the range of valid pages.
            if self.page_number > self.last_page_number:
                self.page_number = self.last_page_number
            elif self.page_number < self.first_page_number:
                self.page_number = self.first_page_number

            # Note: the number of items on this page can be less than page_max_size if the last page is not full.
            self.first_item_index = (self.page_number - 1) * self.page_max_size
            self.first_item_number = self.first_item_index + 1
            self.last_item_index = min(self.first_item_index + self.page_max_size, self.item_count) - 1
            self.last_item_number = self.last_item_index + 1
            self.page_size = self.last_item_index + 1 - self.first_item_index
        else:
            # No item available.
            self.first_item_index = 0
            self.page_count = 0
            self.page_number = 1
            self.page_size = 0
