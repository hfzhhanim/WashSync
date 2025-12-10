import 'package:flutter/material.dart';
class SignInPage extends StatefulWidget {
	const SignInPage({super.key});
	@override
		SignInPageState createState() => SignInPageState();
	}
class SignInPageState extends State<SignInPage> {
	String textField1 = '';
	String textField2 = '';
	@override
	Widget build(BuildContext context) {
		return Scaffold(
			body: SafeArea(
				child: Container(
					constraints: const BoxConstraints.expand(),
					color: Color(0xFFFFFFFF),
					child: Column(
						crossAxisAlignment: CrossAxisAlignment.start,
						children: [
							Expanded(
								child: Container(
									width: double.infinity,
									height: double.infinity,
									decoration: BoxDecoration(
										image: DecorationImage(
											image: NetworkImage("https://storage.googleapis.com/tagjs-prod.appspot.com/v1/ahZdDHF8kj/5wawmpzh_expires_30_days.png"),
											fit: BoxFit.cover
										),
									),
									child: Column(
										crossAxisAlignment: CrossAxisAlignment.start,
										children: [
											Expanded(
												child: IntrinsicHeight(
													child: Container(
														width: double.infinity,
														height: double.infinity,
														child: SingleChildScrollView(
															child: Column(
																crossAxisAlignment: CrossAxisAlignment.start,
																children: [
																	IntrinsicHeight(
																		child: Container(
																			margin: const EdgeInsets.only( top: 11, bottom: 44, left: 29, right: 29),
																			width: double.infinity,
																			child: Row(
																				children: [
																					IntrinsicWidth(
																						child: IntrinsicHeight(
																							child: Container(
																								padding: const EdgeInsets.only( bottom: 1),
																								child: Column(
																									crossAxisAlignment: CrossAxisAlignment.start,
																									children: [
																										Text(
																											"9:41",
																											style: TextStyle(
																												color: Color(0xFF110C26),
																												fontSize: 16,
																											),
																										),
																									]
																								),
																							),
																						),
																					),
																					Expanded(
																						child: Container(
																							width: double.infinity,
																							child: SizedBox(),
																						),
																					),
																					Container(
																						margin: const EdgeInsets.only( right: 10),
																						width: 30,
																						height: 17,
																						child: Image.network(
																							"https://storage.googleapis.com/tagjs-prod.appspot.com/v1/ahZdDHF8kj/edt1fp0r_expires_30_days.png",
																							fit: BoxFit.fill,
																						)
																					),
																					Container(
																						margin: const EdgeInsets.only( right: 6),
																						width: 22,
																						height: 17,
																						child: Image.network(
																							"https://storage.googleapis.com/tagjs-prod.appspot.com/v1/ahZdDHF8kj/bqu7o1x6_expires_30_days.png",
																							fit: BoxFit.fill,
																						)
																					),
																					Container(
																						width: 34,
																						height: 17,
																						child: Image.network(
																							"https://storage.googleapis.com/tagjs-prod.appspot.com/v1/ahZdDHF8kj/4baz7n6a_expires_30_days.png",
																							fit: BoxFit.fill,
																						)
																					),
																				]
																			),
																		),
																	),
																	IntrinsicWidth(
																		child: IntrinsicHeight(
																			child: Container(
																				margin: const EdgeInsets.only( bottom: 49, left: 89),
																				child: Column(
																					children: [
																						Container(
																							width: 147,
																							height: 121,
																							child: Image.network(
																								"https://storage.googleapis.com/tagjs-prod.appspot.com/v1/ahZdDHF8kj/xb1ndge0_expires_30_days.png",
																								fit: BoxFit.fill,
																							)
																						),
																						Text(
																							"WashSync",
																							style: TextStyle(
																								color: Color(0xFF060518),
																								fontSize: 36,
																							),
																						),
																						Text(
																							"Save time. Stay fresh.",
																							style: TextStyle(
																								color: Color(0xFFCB30E0),
																								fontSize: 20,
																							),
																						),
																					]
																				),
																			),
																		),
																	),
																	IntrinsicHeight(
																		child: Container(
																			decoration: BoxDecoration(
																				border: Border.all(
																					color: Color(0xCCC465E4),
																					width: 1,
																				),
																				borderRadius: BorderRadius.circular(15),
																				color: Color(0xFFFFFFFF),
																				boxShadow: [
																					BoxShadow(
																						color: Color(0x40000000),
																						blurRadius: 4,
																						offset: Offset(0, 4),
																					),
																				],
																			),
																			margin: const EdgeInsets.only( bottom: 113, left: 30, right: 30),
																			width: double.infinity,
																			child: Column(
																				crossAxisAlignment: CrossAxisAlignment.start,
																				children: [
																					Container(
																						margin: const EdgeInsets.only( top: 30, bottom: 12, left: 80),
																						child: Text(
																							"Welcome Back",
																							style: TextStyle(
																								color: Color(0xFF000000),
																								fontSize: 24,
																							),
																						),
																					),
																					IntrinsicHeight(
																						child: Container(
																							margin: const EdgeInsets.only( bottom: 42),
																							width: double.infinity,
																							child: Column(
																								children: [
																									Text(
																										"Sign in to your WashSync account",
																										style: TextStyle(
																											color: Color(0xFF000000),
																											fontSize: 16,
																										),
																									),
																								]
																							),
																						),
																					),
																					IntrinsicHeight(
																						child: Container(
																							margin: const EdgeInsets.only( bottom: 26, left: 17, right: 17),
																							width: double.infinity,
																							child: Column(
																								crossAxisAlignment: CrossAxisAlignment.start,
																								children: [
																									Container(
																										margin: const EdgeInsets.only( bottom: 5, left: 4),
																										child: Text(
																											"Email",
																											style: TextStyle(
																												color: Color(0xFF000000),
																												fontSize: 20,
																											),
																										),
																									),
																									IntrinsicHeight(
																										child: Container(
																											decoration: BoxDecoration(
																												border: Border.all(
																													color: Color(0x80C565E4),
																													width: 1,
																												),
																												borderRadius: BorderRadius.circular(8),
																												color: Color(0xFFFFFFFF),
																											),
																											padding: const EdgeInsets.only( left: 8, right: 8),
																											width: double.infinity,
																											child: Row(
																												children: [
																													Container(
																														margin: const EdgeInsets.only( right: 10),
																														width: 28,
																														height: 18,
																														child: Image.network(
																															"https://storage.googleapis.com/tagjs-prod.appspot.com/v1/ahZdDHF8kj/rn10mtmz_expires_30_days.png",
																															fit: BoxFit.fill,
																														)
																													),
																													Expanded(
																														child: IntrinsicHeight(
																															child: Container(
																																alignment: Alignment.center,
																																margin: const EdgeInsets.only( right: 4),
																																width: double.infinity,
																																child: TextField(
																																	style: TextStyle(
																																		color: Color(0xFFA7A7A7),
																																		fontSize: 16,
																																	),
																																	onChanged: (value) { 
																																		setState(() { textField1 = value; });
																																	},
																																	decoration: InputDecoration(
																																		hintText: "you@student.usm.my",
																																		isDense: true,
																																		contentPadding: const EdgeInsets.symmetric(vertical: 10),
																																		border: InputBorder.none,
																																		focusedBorder: InputBorder.none,
																																		filled: false,
																																	),
																																),
																															),
																														),
																													),
																												]
																											),
																										),
																									),
																								]
																							),
																						),
																					),
																					Container(
																						margin: const EdgeInsets.only( bottom: 2, left: 21),
																						child: Text(
																							"Password",
																							style: TextStyle(
																								color: Color(0xFF000000),
																								fontSize: 20,
																							),
																						),
																					),
																					IntrinsicHeight(
																						child: Container(
																							decoration: BoxDecoration(
																								border: Border.all(
																									color: Color(0x80C565E4),
																									width: 1,
																								),
																								borderRadius: BorderRadius.circular(8),
																								color: Color(0xFFFFFFFF),
																							),
																							padding: const EdgeInsets.only( left: 8, right: 8),
																							margin: const EdgeInsets.only( bottom: 6, left: 17, right: 17),
																							width: double.infinity,
																							child: Row(
																								children: [
																									Container(
																										margin: const EdgeInsets.only( right: 10),
																										width: 34,
																										height: 28,
																										child: Image.network(
																											"https://storage.googleapis.com/tagjs-prod.appspot.com/v1/ahZdDHF8kj/hsybajr6_expires_30_days.png",
																											fit: BoxFit.fill,
																										)
																									),
																									Expanded(
																										child: IntrinsicHeight(
																											child: Container(
																												alignment: Alignment.center,
																												margin: const EdgeInsets.only( right: 4),
																												width: double.infinity,
																												child: TextField(
																													style: TextStyle(
																														color: Color(0xFFA7A7A7),
																														fontSize: 16,
																													),
																													onChanged: (value) { 
																														setState(() { textField2 = value; });
																													},
																													decoration: InputDecoration(
																														hintText: "................",
																														isDense: true,
																														contentPadding: const EdgeInsets.symmetric(vertical: 16),
																														border: InputBorder.none,
																														focusedBorder: InputBorder.none,
																														filled: false,
																													),
																												),
																											),
																										),
																									),
																								]
																							),
																						),
																					),
																					Container(
																						margin: const EdgeInsets.only( bottom: 36, left: 21),
																						child: Text(
																							"**Forgot Password**",
																							style: TextStyle(
																								color: Color(0xFFA500FF),
																								fontSize: 14,
																							),
																						),
																					),
																					IntrinsicHeight(
																						child: Container(
																							margin: const EdgeInsets.only( bottom: 36, left: 17, right: 17),
																							width: double.infinity,
																							child: Stack(
																								clipBehavior: Clip.none,
																								children: [
																									Column(
																										crossAxisAlignment: CrossAxisAlignment.start,
																										children: [
																											Container(
																												decoration: BoxDecoration(
																													border: Border.all(
																														color: Color(0xFFBCACCF),
																														width: 1,
																													),
																													borderRadius: BorderRadius.circular(10),
																													color: Color(0xFFA500FF),
																													boxShadow: [
																														BoxShadow(
																															color: Color(0xCCC465E4),
																															blurRadius: 4,
																															offset: Offset(0, 4),
																														),
																													],
																												),
																												height: 37,
																												width: double.infinity,
																												child: SizedBox(),
																											),
																										]
																									),
																									Positioned(
																										bottom: 0,
																										left: 109,
																										width: 67,
																										height: 27,
																										child: Container(
																											transform: Matrix4.translationValues(0, 1, 0),
																											child: Text(
																												"Sign In",
																												style: TextStyle(
																													color: Color(0xFFFFFFFF),
																													fontSize: 20,
																												),
																											),
																										),
																									),
																								]
																							),
																						),
																					),
																					IntrinsicHeight(
																						child: Container(
																							margin: const EdgeInsets.only( bottom: 19),
																							width: double.infinity,
																							child: Column(
																								children: [
																									Text(
																										"Don\'t have an account?  Sign up",
																										style: TextStyle(
																											color: Color(0xFFA500FF),
																											fontSize: 16,
																										),
																									),
																								]
																							),
																						),
																					),
																				]
																			),
																		),
																	),
																],
															)
														),
													),
												),
											),
										]
									),
								),
							),
						],
					),
				),
			),
		);
	}
}