% THIS FUNCTION CALLS THE SCREEN TO SHOW THE RESPONSE IS OVERTIME AND SHOWS
% THE MONEY PENALTY (Pun_cents) AND STAYS ON THE SCREEN FOR (laten) SECONDS

function RTDeadline(PTBParams)


DrawFormattedText(PTBParams.win,PTBParams.Missed_msg, 'center','center', PTBParams.white);%
Screen(PTBParams.win,'Flip');
% putvalue(dio,200);
% rew=rew+Pun_cents;
WaitSecs(0.5);
