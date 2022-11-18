" Sample code from the blog post https://jacekw.dev/blog/2022/oauth-authorization-code-from-abap-on-premise
CLASS zcl_oauth_ac_client DEFINITION PUBLIC FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    METHODS:
      run.

  PRIVATE SECTION.
    METHODS:
      prepare_http_client,
      request_token,
      call_backend,
      set_token RAISING cx_oa2c.

    DATA:
      http_client TYPE REF TO if_http_client.
ENDCLASS.

CLASS zcl_oauth_ac_client IMPLEMENTATION.
  METHOD run.
    prepare_http_client( ).

    TRY.
        set_token( ).
        call_backend( ).
      CATCH cx_oa2c_at_not_available
            cx_oa2c_at_expired.

        request_token( ).
        RETRY.
      CATCH cx_root INTO DATA(exception).
        WRITE: / exception->get_text( ).
    ENDTRY.
  ENDMETHOD.

  METHOD call_backend.

    " Configure the rest of your call
    me->http_client->request->set_header_field(
      name  = '~request_method'
      value = 'GET' ).

    me->http_client->send(
     EXCEPTIONS
      http_communication_failure = 1
      http_invalid_state         = 2 ).

    IF sy-subrc <> 0.
      " handle error...
      RETURN.
    ENDIF.

    http_client->receive(
      EXCEPTIONS
      http_communication_failure = 1
      http_invalid_state         = 2
      http_processing_failed     = 3 ).

    IF sy-subrc <> 0.
      " handle error...
      RETURN.
    ENDIF.

    DATA(response) = http_client->response->get_cdata( ).
    cl_demo_output=>display_text( response ).

  ENDMETHOD.

  METHOD prepare_http_client.
    cl_http_client=>create_by_destination(
     EXPORTING
       destination              = 'VERCEL_BACKEND_AC'
     IMPORTING
       client                   = me->http_client
     EXCEPTIONS
       argument_not_found       = 1
       destination_not_found    = 2
       destination_no_authority = 3
       plugin_not_active        = 4
       OTHERS                   = 5 ).

    IF sy-subrc <> 0.
      " handle error...
    ENDIF.
  ENDMETHOD.

  METHOD request_token.
    cl_abap_browser=>show_url( url = 'https://localhost:50001/sap/bc/sec/oauth2/client/grant/authorization?profile=Z_AUTH0_AC_PROFILE' ).
  ENDMETHOD.

  METHOD set_token.
    DATA(outh_client) = cl_oauth2_client=>create(
      i_profile = 'Z_AUTH0_AC_PROFILE'
      i_configuration = 'Z_AUTH0_AC_PROFILE' ).

    outh_client->set_token(
      io_http_client = me->http_client
      i_param_kind = if_oauth2_client=>c_param_kind_header_field ).
  ENDMETHOD.
ENDCLASS.
