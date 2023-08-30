DECLARE
  v_diff VARCHAR2(4000); -- Переменная для хранения различающихся строк
BEGIN
  FOR i in (SELECT t1.msisdn_to msisdn_to, MUST_SEND, ACTUAL_SENT, MUST_SEND - ACTUAL_SENT DIFFERENCE
  FROM (SELECT to_char(b.number_value) MSISDN_TO, count(1) MUST_SEND
          FROM bis.OBJ_EXTENTED_VALUE b -- Выборка из таблицы правил
         where obj_id in (select d.obj_id
                            from (SELECT a.obj_id,
                                         case
                                           when to_char(sysdate, 'hh24') = '15' and -- Условия для времени сутки если 8 часов утра то не берем из адресатов Gross adds
                                                a.varchar_value <> 'Gross adds' then
                                            15
                                           when to_char(sysdate, 'hh24') = '21' then -- Условия для времени сутки если 21 часов вечера то берем из адресатов Gross adds
                                            21
                                         end values_X --obj_id
                                    FROM bis.OBJ_EXTENTED_VALUE a
                                   where a.group_id = 1541
                                     and a.end_date >= sysdate - 1
                                     and a.param_num = 4
                                     and a.varchar_value in
                                         ('Gross adds', -- Список адресатов
                                          'Revenue UZS',
                                          'Subs Info',
                                          'Prepaid',
                                          'ITC PL',
                                          'Postpaid',
                                          'Campaigns')) d
                           where d.values_X is not null)
           and b.number_value like '998%'
           and b.number_value not in ('99893874', '99893872', '99893854') -- Номера не должны быть похоже на этих
           and b.end_date > sysdate
           and b.group_id = 1541
         group by number_value) t1
  LEFT JOIN (select cc.MSISDN_TO, count(1) ACTUAL_SENT  -- Через LEFT JOIN соединяем 2 выборки и получаем разницу 
               from (select c.*, --MSISDN_TO, count(1) count1
                            case
                              when to_char(sysdate,
                                           'hh24') = '15' and  -- Условия для времени сутки если 8 часов утра то не берем СМС отправленные в Gross adds
                                   c.msisdn_from <> 'Gross adds' then
                               15
                              when to_char(sysdate,
                                           'hh24') = '21' then -- Условия для времени сутки если 21 часов вечера то берем СМС отправленные в Gross adds
                               21
                            end values_X
                       from cnc.SMS_202308_1 c -- Выборка из таблицы отправленных СМС
                      where clnt_clnt_id = 0
                        and smgt_smgt_id = 2001
                        and msisdn_from in ('Gross adds',
                                            'Revenue UZS',
                                            'Subs Info',
                                            'Prepaid',
                                            'ITC PL',
                                            'Postpaid',
                                            'Campaigns')
                        and trunc(send_date) >= sysdate - 1) cc
              where cc.values_x is not null
              group by cc.MSISDN_TO) t2
    ON t1.msisdn_to = t2.msisdn_to) LOOP
      
      IF i.MUST_SEND <> i.ACTUAL_SENT THEN -- Проверяем если кол-во СМС в правиле и отправленных СМС не равны 
        v_diff := v_diff||i.msisdn_to||' '||i.MUST_SEND||' '||i.ACTUAL_SENT||' '||i.DIFFERENCE||CHR(10); -- то выводим эти данные
      ELSIF i.MUST_SEND = i.ACTUAL_SENT THEN -- Проверяем если кол-во СМС в правиле и отправFленных СМС равны 
        v_diff := v_diff||i.msisdn_to||' '||i.MUST_SEND||' '||i.ACTUAL_SENT||' '||i.DIFFERENCE||CHR(10); -- то выводим эти данные
      END IF;
    END LOOP;

  -- Выводим различающиеся строки на экран
  DBMS_OUTPUT.PUT_LINE('Report:');
  DBMS_OUTPUT.PUT_LINE(v_diff);
END;
/


