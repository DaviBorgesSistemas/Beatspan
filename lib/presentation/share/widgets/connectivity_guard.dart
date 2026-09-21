// © 2026 Davi Borges <daviborges.sistemas@gmail.com>
// Projeto : Beatspan
// Website : 
// Token   : AFA32A23171530AD
// @wm:AFA32A23171530AD
//
// Todos os direitos reservados.

import 'package:flutter/material.dart';

import '../../../app/di.dart';
import '../../../data/network/network_info.dart';
import 'no_internet_view.dart';

extension ConnectivityGuard on BuildContext {
  Future<bool> requireInternetConnection() async {
    final isConnected = await instance<NetworkInfo>().isConnected;
    if (isConnected) return true;

    if (!mounted) return false;
    await Navigator.of(
      this,
    ).push(MaterialPageRoute(builder: (_) => const NoInternetView()));
    return false;
  }
}
