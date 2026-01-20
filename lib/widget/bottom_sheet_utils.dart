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
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return CreateNewTicketForm( ticket: ticketParm );
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
