
import 'package:achiva/core/Constants/constants.dart';
import 'package:achiva/core/components/loading_widget.dart';
import 'package:achiva/core/components/no_internet_found_column_widget.dart';
import 'package:achiva/core/components/server_failure_column_widget.dart';
import 'package:achiva/core/constants/extensions.dart';
import 'package:achiva/core/errors/app_failures.dart';
import 'package:achiva/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../layout_controller/layout_cubit.dart';
import '../../layout_controller/layout_states.dart';

class UserGoalsListviewWidget extends StatefulWidget {
  final LayoutCubit layoutCubit;
  const UserGoalsListviewWidget({super.key, required this.layoutCubit});

  @override
  State<UserGoalsListviewWidget> createState() => _UserGoalsListviewWidgetState();
}

class _UserGoalsListviewWidgetState extends State<UserGoalsListviewWidget> {
  @override
  void initState() {
    widget.layoutCubit.getMyGoals();
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LayoutCubit,LayoutStates>(
      builder: (context,state){
        if( widget.layoutCubit.myGoals.isNotEmpty )
          {
            return ListView.separated(
              itemCount: widget.layoutCubit.myGoals.length,
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              separatorBuilder: AppConstants.kSeparatorBuilder(),
              itemBuilder: (context,index)=> Container(
                padding: AppConstants.kContainerPadding,
                decoration: BoxDecoration(
                  color: AppColors.kWhiteColor,
                  borderRadius: AppConstants.kMainRadius
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.layoutCubit.myGoals[index].name,style: TextStyle(fontSize: 16,fontWeight: FontWeight.w600,color: AppColors.kBlack),),
                    8.vrSpace,
                    Align(
                      alignment: AlignmentDirectional.topEnd,
                      child: Text(DateFormat('yyyy-MM-dd').format(widget.layoutCubit.myGoals[index].date),style: TextStyle(fontSize: 14,fontWeight: FontWeight.w500,color: AppColors.kLightGrey),),
                    )
                  ],
                ),
              ),
            );
          }
        else if ( state is GetUserGoalsWithFailureState )
          {
            if( state.failure.runtimeType == InternetNotFoundFailure )
              {
                return InternetLostColumnWidget(retryFunction: ()=> widget.layoutCubit.getMyGoals());
              }
            else
              {
                return const ServerFailureColumnWidget();
              }
          }
        else
          {
            if( state is GetUserGoalsSuccessfullyState && widget.layoutCubit.myGoals.isEmpty )
              {
                return Container(
                  alignment: Alignment.center,
                  height: 300,
                  child: Text("No Goals created until now !",style: TextStyle(fontSize: 16,fontWeight: FontWeight.w600,color: AppColors.kBlack),),
                );
              }
            else
              {
                return const SizedBox(height: 300,child: LoadingWidget(message: "Loading User Goals"));
              }
          }
      },
    );
  }
}
