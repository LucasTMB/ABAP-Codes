REPORT zexerc_frequencia.

*** Ini - LUBARROS - Relatório de Frequência dos Alunos - 15.04.2024 10:09:38 ***

" Layout da ALV -----------------------------------------------------
DATA: lo_alv              TYPE REF TO cl_salv_table,
      lex_message         TYPE REF TO cx_salv_msg,
      lo_layout_settings  TYPE REF TO cl_salv_layout,
      lo_layout_key       TYPE        salv_s_layout_key,
      lo_columns          TYPE REF TO cl_salv_columns_table,
      lo_column           TYPE REF TO cl_salv_column,
      lex_not_found       TYPE REF TO cx_salv_not_found,
      lo_functions        TYPE REF TO cl_salv_functions_list,
      lo_display_settings TYPE REF TO cl_salv_display_settings.

" Armazenamento das datas pesquisadas -------------------------------
DATA: data_pesquisa_low  TYPE datum,
      data_pesquisa_high TYPE datum.

" Variáveis para o cabeçalho ----------------------------------------
DATA: lo_header  TYPE REF TO cl_salv_form_layout_grid,
      lo_h_label TYPE REF TO cl_salv_form_label,
      lo_h_flow  TYPE REF TO cl_salv_form_layout_flow.

" Criação do tipo (estrutura) da tabela -----------------------------
TYPES: BEGIN OF ty_frequencia,
         nome_aluno       TYPE zalunos-nome_aluno,
         nome_turma       TYPE zturma-nome_turma,
         nome_disciplina  TYPE zdiscplina-nome_discplina,
         presencas        TYPE zfrequencia-presenca,
         percentual_falta TYPE p DECIMALS 2,
       END OF ty_frequencia.

" Criação da nova tabela e variáveis necessárias para a lógica ------
DATA: lt_frequencia          TYPE TABLE OF ty_frequencia,
      ls_frequencia          TYPE ty_frequencia,
      lv_current_disciplina  TYPE zdiscplina-nome_discplina,
      ld_percentual_presenca TYPE p DECIMALS 2,
      ld_percentual_falta    TYPE p DECIMALS 2,
      lv_count_registros     TYPE i VALUE 1,
      lv_count_presenca      TYPE i VALUE 0,
      l_index                TYPE sy-tabix.  "Verifica o index atual da tabela"

TABLES: zfrequencia, zalunos, zturma, zdiscplina.

"Exibição da tela de pesquisa"
SELECTION-SCREEN BEGIN OF BLOCK b1.
  PARAMETERS: p_id  TYPE zalunos-id. "MATCHCODE OBJECT ZSH_NOME_ID."
  PARAMETERS: p_name TYPE zalunos-nome_aluno.
SELECTION-SCREEN END OF BLOCK b1.

SELECT-OPTIONS: so_date FOR zfrequencia-data.

START-OF-SELECTION.
  IF so_date IS NOT INITIAL.
    data_pesquisa_low = so_date-low.
    data_pesquisa_high = so_date-high.
    IF so_date-low+4(2) BETWEEN 1 AND 6.   "Verifica se o mês está localizado no primeiro semestre ou não"
*    WRITE 'primeiro semeste'.
      IF so_date-high(4) > so_date-low(4). "Verifica se o ano da data final é maior do que o inicial"
        IF so_date-high+4(2) <= so_date-low+4(2) AND so_date-high+6(2) < so_date-low+6(2). "Dia e mês do outro ano é menor do que a data inicial?"
          so_date-high+6(2) = 30.
          so_date-high+4(2) = 06.
          so_date-high(4) = so_date-low(4).
        ELSE.
          so_date-high(4) = so_date-low(4).
        ENDIF.
      ENDIF.
      IF so_date-low+4(2) = 01 AND so_date-high+4(2) => 07. "Verifica se foi incluído o mês de férias nos dois campos"
        so_date-low+6(2) = 01.
        so_date-low+4(2) = 02.
        so_date-high+6(2) = 30.
        so_date-high+4(2) = 06.
      ELSEIF so_date-low+4(2) = 01. " Verifica se apenas o mês inicial está localizado nas férias
        so_date-low+6(2) = 01.
        so_date-low+4(2) = 02.
      ELSEIF so_date-high+4(2) => 07. " Verifica se apenas o mês final está localizado nas férias
        so_date-high+6(2) = 30.
        so_date-high+4(2) = 06.
      ENDIF.
    ELSE.
*    WRITE 'segundo semestre'.
      "Verifica se é mês de férias ou se o ano final é maior que o inicial
      "Isso se deve pois o usuário pode inserir por exemplo: 14.09.2024 até 14.08.2025 e isso não pode acontecer
      IF so_date-low+4(2) = 07 AND ( so_date-high+4(2) = 12 OR ( so_date-high(4) > so_date-low(4) ) ).
        IF so_date-high(4) >= so_date-low(4).
          so_date-high(4) = so_date-low(4).
        ENDIF.
        so_date-low+6(2) = 01.
        so_date-low+4(2) = 08.
        so_date-high+6(2) = 30.
        so_date-high+4(2) = 11.
      ELSEIF so_date-low+4(2) = 07.
        so_date-low+6(2) = 01.
        so_date-low+4(2) = 08.
      ELSEIF so_date-high+4(2) = 12 OR ( so_date-high(4) > so_date-low(4) ).
        IF so_date-high(4) >= so_date-low(4).
          so_date-high(4) = so_date-low(4).
        ENDIF.
        so_date-high+6(2) = 30.
        so_date-high+4(2) = 11.
      ENDIF.
    ENDIF.
*  lv_data1 = so_date-low.
*  lv_data2 = so_date-high.
  ENDIF.

  "Consulta das tabelas e criação da tabela lt_zfrequencia"
  SELECT
    a~nome_aluno,
    t~nome_turma,
    f~data,
    d~nome_discplina,
    f~presenca
    FROM zfrequencia AS f
    INNER JOIN zalunos AS a
    ON f~id_aluno = a~id
    INNER JOIN zdiscplina AS d
    ON f~id_disciplina = d~id_disciplina
    INNER JOIN zturma AS t
    ON t~id_aluno = a~id
    INTO TABLE @DATA(lt_zfrequencia)
    WHERE data IN @so_date
      AND a~id = @p_id
    ORDER BY d~nome_discplina.

  IF sy-subrc = 0.
    LOOP AT lt_zfrequencia INTO DATA(ls_zfrequencia).
      lv_current_disciplina = ls_zfrequencia-nome_discplina.  " Verifica qual é a disciplina atual na tabela
      l_index = sy-tabix.

      READ TABLE lt_zfrequencia INDEX ( l_index + 1 ) INTO DATA(lv_next_discplina). " Soma +1 no index para visualizar a próxima linha

      IF sy-subrc = 0. " Se sy-subrc for 0, quer dizer que existe uma próxima linha
        IF lv_next_discplina-nome_discplina <> lv_current_disciplina. " Se a próxima disciplina for diferente da atual, é hora de add uma linha
          ls_frequencia-nome_aluno = ls_zfrequencia-nome_aluno.
          ls_frequencia-nome_turma = ls_zfrequencia-nome_turma.
          ls_frequencia-nome_disciplina = ls_zfrequencia-nome_discplina.
          IF ls_zfrequencia-presenca = 'P'.
            lv_count_presenca = lv_count_presenca + 1.
          ENDIF.
          ls_frequencia-presencas = lv_count_presenca.
          IF so_date IS NOT INITIAL.  " O cálculo só é realizado se o usuário inserir datas
            ld_percentual_presenca = ( ls_frequencia-presencas / lv_count_registros ) * 100.
            ls_frequencia-percentual_falta = 100 - ld_percentual_presenca.
          ENDIF.
          APPEND ls_frequencia TO lt_frequencia.
          lv_count_registros = 1.
          lv_count_presenca = 0.
        ELSE. " Se a próxima disciplina for a mesma, quer dizer que existe mais registros e possivelmente mais presenças
          lv_count_registros = lv_count_registros + 1.
          IF ls_zfrequencia-presenca = 'P'.
            lv_count_presenca = lv_count_presenca + 1.
          ENDIF.
        ENDIF.
      ELSE. " Devemos repetir a lógica da próxima disciplina, só que dessa vez, é add um novo registro caso não exista mais linhas adiante
        ls_frequencia-nome_aluno = ls_zfrequencia-nome_aluno.
        ls_frequencia-nome_turma = ls_zfrequencia-nome_turma.
        ls_frequencia-nome_disciplina = ls_zfrequencia-nome_discplina.
        IF ls_zfrequencia-presenca = 'P'.
          lv_count_presenca = lv_count_presenca + 1.
        ENDIF.
        ls_frequencia-presencas = lv_count_presenca.
        IF so_date IS NOT INITIAL.
          "WRITE: lv_count_presenca, lv_count_registros.
          ld_percentual_presenca = ( ls_frequencia-presencas / lv_count_registros ) * 100.
          ls_frequencia-percentual_falta = 100 - ld_percentual_presenca.
        ENDIF.
        APPEND ls_frequencia TO lt_frequencia.
*    lv_count_registros = 1.
*    lv_count_presenca = 1.
      ENDIF.
    ENDLOOP.

    TRY.
        cl_salv_table=>factory(
          IMPORTING
            r_salv_table = lo_alv
          CHANGING
            t_table      = lt_frequencia ).

      CATCH cx_salv_msg INTO lex_message.

    ENDTRY.

    " Código da Layout da ALV
    lo_layout_settings   = lo_alv->get_layout( ).
    lo_layout_key-report = sy-repid.
    lo_layout_settings->set_key( lo_layout_key ).
    lo_layout_settings->set_save_restriction( if_salv_c_layout=>restrict_none ).

    lo_functions = lo_alv->get_functions( ).
    lo_functions->set_all( ).

    lo_columns = lo_alv->get_columns( ).
    lo_columns->set_optimize( ).

    lo_display_settings = lo_alv->get_display_settings( ).
    lo_display_settings->set_striped_pattern( if_salv_c_bool_sap=>true ).

    lo_display_settings->set_list_header( TEXT-001 ).

    " Ajuste no nome das colunas da ALV (é necessário colocar a referência em maiúsculo)
    TRY.
        lo_column = lo_columns->get_column( 'NOME_ALUNO' ).
        lo_column->set_short_text( 'Aluno' ).
        lo_column->set_medium_text( 'Nome do Aluno' ).
        lo_column->set_long_text( 'Nome do Aluno' ).

        lo_column = lo_columns->get_column( 'NOME_TURMA' ).
        lo_column->set_short_text( 'Turma' ).
        lo_column->set_medium_text( 'Nome da Turma' ).
        lo_column->set_long_text( 'Nome da Turma' ).

        lo_column = lo_columns->get_column( 'NOME_DISCIPLINA' ).
        lo_column->set_short_text( 'Disciplina' ).
        lo_column->set_medium_text( 'Nome da Disciplina' ).
        lo_column->set_long_text( 'Nome da Disciplina' ).

        lo_column = lo_columns->get_column( 'PRESENCAS' ).
        lo_column->set_short_text( 'Presenças' ).
        lo_column->set_medium_text( 'Qtd. Presenças' ).
        lo_column->set_long_text( 'Quantidade de Presenças' ).

        lo_column = lo_columns->get_column( 'PERCENTUAL_FALTA' ).
        lo_column->set_short_text( 'Falta' ).
        lo_column->set_medium_text( 'Falta(%)' ).
        lo_column->set_long_text( 'Falta(%)' ).
      CATCH cx_salv_not_found INTO lex_not_found.
*      » write some error handling
    ENDTRY.

*** Ini - iumachado - Criação DO cabeçalho - 16.04.2024 11:11:22 ***

  CREATE OBJECT lo_header.
*   Writing Bold phrase
    lo_h_label = lo_header->create_label( row = 1 column = 1 ).
    lo_h_label->set_text( 'Relatorio de Frequência!' ).
*   Writing Header texts
    lo_h_flow = lo_header->create_flow( row = 2  column = 1 ).
    lo_h_flow->create_text( text = 'Data inserida: ' ).
    lo_h_flow = lo_header->create_flow( row = 2  column = 2 ).
    lo_h_flow->create_text( text = data_pesquisa_low ).
    lo_h_flow = lo_header->create_flow( row = 2  column = 3 ).
    lo_h_flow->create_text( text = 'até' ).
    lo_h_flow = lo_header->create_flow( row = 2  column = 4 ).
    lo_h_flow->create_text( text = data_pesquisa_high ).
    lo_h_flow = lo_header->create_flow( row = 3  column = 1 ).
    lo_h_flow->create_text( text = 'Data válida: ' ).
    lo_h_flow = lo_header->create_flow( row = 3  column = 2 ).
    lo_h_flow->create_text( text = so_date-low ).
    lo_h_flow = lo_header->create_flow( row = 3  column = 3 ).
    lo_h_flow->create_text( text = 'até' ).
    lo_h_flow = lo_header->create_flow( row = 3  column = 4 ).
    lo_h_flow->create_text( text = so_date-high ).
*   Set the top of list
    lo_alv->set_top_of_list( lo_header ).
*   Print on top of list
    lo_alv->set_top_of_list_print( lo_header ).

*** Fim - IUMACHADO ***

    lo_alv->display( ).
  ELSE.
    MESSAGE 'NENHUM DADO REFERENTE SUA PESQUISA FOI ENCONTRADO' TYPE 'S' DISPLAY LIKE 'E'.
  ENDIF.

*** Fim - LUBARROS ***