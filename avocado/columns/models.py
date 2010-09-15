"""
The Column class takes an optional setting, 'COLUMN_CONCEPT_MIXIN' which
defines an abstract Model class that can provide references to additional
fields.

The most typical scenario for using this setting is to specify 'formatter'
fields for the Column class to use.
"""

from django.db import models

from avocado.conf import settings
from avocado.modeltree import DEFAULT_MODELTREE_ALIAS, mts
from avocado.concepts.models import Concept, ConceptField
from avocado.fields.models import Field
from avocado.columns.mixins import ColumnMixin

__all__ = ('Column', 'ColumnField')

class Column(Concept, ColumnMixin):
    "An interface to specify the necessary fields for a column."
    fields = models.ManyToManyField(Field, through='ColumnField')

    class Meta(Concept.Meta):
        pass

    # FIXME not optimized at all...
    def rule(self, ftype):
        if not hasattr(self, '_rules'):
            self._rules = {}
        if not self._rules.has_key(ftype):
            if not ftype.endswith(settings.FORMATTER_FIELD_SUFFIX):
                ftype = ftype + settings.FORMATTER_FIELD_SUFFIX
            fmtr = getattr(self, ftype)
            self._rules[ftype] = (fmtr, len(self.fields.all()))
        return self._rules[ftype]

    def add_fields_to_queryset(self, queryset, using=DEFAULT_MODELTREE_ALIAS):
        modeltree = mts[using]

        fields = self.fields.all()
        aliases = []
        for f in fields:
            queryset = modeltree.add_joins(f.model, queryset)
            aliases.append((f.model._meta.db_table, f.field_name))
        return (queryset, aliases)

    def get_ordering_for_queryset(self, direction='asc', using=DEFAULT_MODELTREE_ALIAS):
        fields = self.fields.all()
        orders = []
        for f in fields:
            orders.append(f.order_string(direction, using))
        return orders

class ColumnField(ConceptField):
    concept = models.ForeignKey(Column)
    field = models.ForeignKey(Field, limit_choices_to={'is_public': True})

    class Meta(ConceptField.Meta):
        pass
