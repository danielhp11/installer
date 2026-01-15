import 'package:flutter/material.dart';
import 'package:instaladores_new/view/widget/ticket/create_new_ticket_form.dart';

import '../../service/response_service.dart';

void showFuelFormBottomSheet(
    BuildContext context,
    ApiResTicket? ticketParm
    ) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true, // 🔥 IMPORTANTE
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return CreateNewTicketForm( ticket: ticketParm );
    },
  );
}