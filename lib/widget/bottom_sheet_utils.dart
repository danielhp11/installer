import 'package:flutter/material.dart';
import 'package:instaladores_new/view/widget/ticket/create_new_ticket_form.dart';
import 'package:instaladores_new/view/widget/ticket_job/close_job_ticket.dart';
import 'package:instaladores_new/view/widget/ticket_job/start_job_ticket.dart';

import '../service/response_service.dart';

void showFuelFormBottomSheet(
    BuildContext context,
    ApiResTicket? ticketParm
    ) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    isDismissible: false,
    enableDrag: false,
    backgroundColor: Colors.transparent,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) {
      return Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 4),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: CreateNewTicketForm(ticket: ticketParm),
            ),
          ],
        ),
      );
    },
  );
}


void showStarJobFormBottomSheet(
    BuildContext context,
    ApiResTicket ticketParm
    ) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    isDismissible: false,
    enableDrag: false,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return StartJobTicket( ticket: ticketParm );
    },
  );
}


void showCloseJobFormBottomSheet(
    BuildContext context,
    ApiResTicket ticketParm
    ) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return CloseJobTicket( ticket: ticketParm );
    },
  );
}
