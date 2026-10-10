from odoo import _, fields, models
from odoo.exceptions import UserError


class SaleOrder(models.Model):
    _inherit = 'sale.order'

    payment_status = fields.Selection(
        selection=[('unpaid', 'Non payé'), ('paid', 'Payé')],
        string='Statut de paiement',
        default='unpaid',
        copy=False,
        tracking=True,
    )
    paid_date = fields.Datetime(string='Date de paiement', copy=False, readonly=True)

    def action_mark_as_paid(self):
        """Passe les commandes confirmées à l'état « Payé »."""
        for order in self:
            if order.state not in ('sale', 'done'):
                raise UserError(_(
                    "La commande %s doit être confirmée avant d'être marquée comme payée.",
                    order.name,
                ))
            if order.payment_status == 'paid':
                raise UserError(_("La commande %s est déjà payée.", order.name))
        self.write({
            'payment_status': 'paid',
            'paid_date': fields.Datetime.now(),
        })
        return True
